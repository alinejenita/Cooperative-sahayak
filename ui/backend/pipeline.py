import os
import sys
import json
import re
import io
import pickle
import platform
import wave
from pathlib import Path

import numpy as np
import torch
import faiss
import requests

from rank_bm25 import BM25Okapi
from sentence_transformers import SentenceTransformer

from transformers import (
    AutoTokenizer,
    AutoModelForSeq2SeqLM,
)

from IndicTransToolkit.processor import IndicProcessor
import sherpa_onnx
from piper import PiperVoice

import soundfile as sf
import librosa

# Submission repository root
PROJECT_ROOT = Path(__file__).resolve().parents[2] / "pipeline"
RAG_FILE = PROJECT_ROOT / "data" / "rag_chunks.jsonl"

EMBED_DIR = PROJECT_ROOT / "indexes" / "embeddings_bge"
FAISS_FILE = EMBED_DIR / "faiss.index"
BM25_FILE = EMBED_DIR / "bm25.pkl"

# External model locations; model weights are intentionally not committed.
BGE_MODEL_DIR = Path(
    os.environ.get("COOP_SAHAYAK_BGE_MODEL_DIR", "")
).expanduser()

INDIC_EN_MODEL_DIR = Path(
    os.environ.get("COOP_SAHAYAK_INDIC_EN_MODEL_DIR", "")
).expanduser()

EN_INDIC_MODEL_DIR = Path(
    os.environ.get("COOP_SAHAYAK_EN_INDIC_MODEL_DIR", "")
).expanduser()

ASR_BASE_DIR = Path(
    os.environ.get("COOP_SAHAYAK_ASR_DIR", "")
).expanduser()

ASR_SAMPLE_RATE = 16000
ASR_FEATURE_DIM = 80
ASR_NUM_THREADS = 4
ASR_LANGS = ["ta", "hi", "te", "kn", "ml"]

TTS_DIR = Path(os.environ.get("COOP_SAHAYAK_TTS_DIR", "")).expanduser()
TTS_OUTPUT_DIR = PROJECT_ROOT / "outputs"
TTS_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

LLAMA_BASE_URL = "http://127.0.0.1:8080"
LLAMA_COMPLETION_URL = f"{LLAMA_BASE_URL}/completion"

SUPPORTED_LANGS = ["ta", "hi", "te", "kn", "ml"]

LANG_NAMES = {
    "ta": "Tamil",
    "hi": "Hindi",
    "te": "Telugu",
    "kn": "Kannada",
    "ml": "Malayalam",
}

TRANSLATION_SRC_LANGS = {
    "ta": "tam_Taml",
    "hi": "hin_Deva",
    "te": "tel_Telu",
    "kn": "kan_Knda",
    "ml": "mal_Mlym",
}

TRANSLATION_TARGET_LANG = "eng_Latn"
EN_INDIC_SOURCE_LANG = "eng_Latn"

EN_INDIC_TARGET_LANGS = {
    "ta": "tam_Taml",
    "hi": "hin_Deva",
    "te": "tel_Telu",
    "kn": "kan_Knda",
    "ml": "mal_Mlym",
}

TOP_K = 3
CANDIDATE_K = 15
RAG_MIN_DENSE_SCORE = 0.45
RAG_FALLBACK = "Sorry, I couldn't answer your question from the available information."

# Load RAG Corpus
records = []
with RAG_FILE.open("r", encoding="utf-8") as f:
    for line_number, line in enumerate(f, start=1):
        line = line.strip()
        if not line:
            continue
        records.append(json.loads(line))

normalized_records = []
for record in records:
    metadata = record.get("metadata", {})
    normalized_records.append({
        "id": record.get("id", ""),
        "text": record.get("text", ""),
        "source_file": metadata.get("source_file", ""),
        "source_path": metadata.get("source_path", ""),
        "document_id": metadata.get("document_id", ""),
        "document_type": metadata.get("document_type", ""),
        "region": metadata.get("region", ""),
        "language": metadata.get("language", ""),
        "chunk_index": metadata.get("chunk_index", ""),
        "total_chunks": metadata.get("total_chunks", ""),
        "content_hash": metadata.get("content_hash", ""),
    })

# Load FAISS, BM25, and BGE Model
faiss_index = faiss.read_index(str(FAISS_FILE))

with BM25_FILE.open("rb") as f:
    bm25 = pickle.load(f)

embed_model = SentenceTransformer(
    str(BGE_MODEL_DIR),
    device="cpu",
)

BM25_STOPWORDS = {
    "what", "is", "the", "a", "an", "are", "was", "were",
    "be", "been", "being", "of", "to", "in", "on", "for",
    "from", "by", "with", "and", "or", "as", "at", "this",
    "that", "these", "those", "it", "its", "how", "why",
    "when", "where", "which", "who", "does", "do", "did",
    "can", "could", "should", "would", "will",
}

def bm25_tokenize(text):
    tokens = re.findall(r"[a-z0-9]+", str(text).lower())
    return [t for t in tokens if t not in BM25_STOPWORDS]

def hybrid_search(query, top_k=TOP_K, candidate_k=CANDIDATE_K):
    if not query or not query.strip():
        return []

    q_embed = embed_model.encode(
        [query],
        normalize_embeddings=True,
        convert_to_numpy=True,
    )

    faiss_scores, faiss_indices = faiss_index.search(q_embed, candidate_k)

    dense_candidates = {}
    for idx, score in zip(faiss_indices[0], faiss_scores[0]):
        if idx != -1:
            dense_candidates[int(idx)] = float(score)

    top_dense_score = (
        max(dense_candidates.values()) if dense_candidates else 0.0
    )

    if top_dense_score < RAG_MIN_DENSE_SCORE:
        return []

    tokens = bm25_tokenize(query)
    bm25_scores = (
        bm25.get_scores(tokens) if tokens else np.zeros(len(normalized_records))
    )

    candidate_ids = set(dense_candidates.keys())

    if candidate_ids:
        max_bm25 = max([bm25_scores[i] for i in candidate_ids] + [1.0])
    else:
        max_bm25 = 1.0

    bm25_max_ref = max(max_bm25, 1e-6)

    combined = []
    for idx in candidate_ids:
        dense_s = dense_candidates[idx]
        bm25_s = float(bm25_scores[idx]) / bm25_max_ref
        combined_score = 0.7 * dense_s + 0.3 * bm25_s

        rec = normalized_records[idx].copy()
        rec["dense_score"] = dense_s
        rec["bm25_score"] = float(bm25_scores[idx])
        rec["combined_score"] = combined_score
        combined.append(rec)

    combined.sort(key=lambda x: x["combined_score"], reverse=True)
    return combined[:top_k]

# Translation Models
TRANSLATION_DEVICE = "cpu"

translator_tokenizer = AutoTokenizer.from_pretrained(
    str(INDIC_EN_MODEL_DIR),
    local_files_only=True,
    trust_remote_code=True,
)
translator_model = AutoModelForSeq2SeqLM.from_pretrained(
    str(INDIC_EN_MODEL_DIR),
    local_files_only=True,
    trust_remote_code=True,
).to(TRANSLATION_DEVICE)
translator_model.eval()

indic_processor = IndicProcessor(inference=True)

en_indic_tokenizer = AutoTokenizer.from_pretrained(
    str(EN_INDIC_MODEL_DIR),
    local_files_only=True,
    trust_remote_code=True,
)
en_indic_model = AutoModelForSeq2SeqLM.from_pretrained(
    str(EN_INDIC_MODEL_DIR),
    local_files_only=True,
    trust_remote_code=True,
).to(TRANSLATION_DEVICE)
en_indic_model.eval()

en_indic_processor = IndicProcessor(inference=True)

def translate_to_english(text, language_code, max_length=128):
    if language_code not in TRANSLATION_SRC_LANGS:
        raise ValueError(f"Unsupported language: {language_code}")
    if not isinstance(text, str) or not text.strip():
        raise ValueError("Input text must be a non-empty string.")

    src_lang = TRANSLATION_SRC_LANGS[language_code]

    batch = indic_processor.preprocess_batch(
        [text],
        src_lang=src_lang,
        tgt_lang=TRANSLATION_TARGET_LANG,
    )

    inputs = translator_tokenizer(
        batch,
        padding=True,
        truncation=True,
        return_tensors="pt",
    )

    inputs = {
        key: value.to(TRANSLATION_DEVICE)
        for key, value in inputs.items()
    }

    with torch.no_grad():
        generated_tokens = translator_model.generate(
            **inputs,
            use_cache=False,
            max_length=max_length,
            num_beams=1,
            do_sample=False,
            num_return_sequences=1,
        )

    decoded = translator_tokenizer.batch_decode(
        generated_tokens,
        skip_special_tokens=True,
    )

    translated = indic_processor.postprocess_batch(
        decoded,
        lang=TRANSLATION_TARGET_LANG,
    )

    return translated[0].strip()

def translate_english_to_indic(text, language_code, max_length=512):
    if language_code not in EN_INDIC_TARGET_LANGS:
        raise ValueError(f"Unsupported language: {language_code}")
    if not isinstance(text, str) or not text.strip():
        raise ValueError("Input text must be a non-empty string.")

    tgt_lang = EN_INDIC_TARGET_LANGS[language_code]

    batch = en_indic_processor.preprocess_batch(
        [text],
        src_lang=EN_INDIC_SOURCE_LANG,
        tgt_lang=tgt_lang,
    )

    inputs = en_indic_tokenizer(
        batch,
        padding=True,
        truncation=True,
        return_tensors="pt",
    )

    inputs = {
        key: value.to(TRANSLATION_DEVICE)
        for key, value in inputs.items()
    }

    with torch.no_grad():
        generated_tokens = en_indic_model.generate(
            **inputs,
            use_cache=False,
            max_length=max_length,
            num_beams=1,
            do_sample=False,
            num_return_sequences=1,
        )

    decoded = en_indic_tokenizer.batch_decode(
        generated_tokens,
        skip_special_tokens=True,
    )

    translated = en_indic_processor.postprocess_batch(
        decoded,
        lang=tgt_lang,
    )

    return translated[0].strip()

# Navarasa Grounded LLM Completion
def navarasa_completion(prompt, max_tokens=320, temperature=0.0):
    payload = {
        "prompt": prompt,
        "n_predict": max_tokens,
        "temperature": temperature,
        "stop": ["USER QUESTION:", "RETRIEVED SOURCE TEXT:", "ANSWER:"],
    }
    response = requests.post(
        LLAMA_COMPLETION_URL,
        json=payload,
        timeout=60,
    )
    response.raise_for_status()
    data = response.json()
    return data.get("content", "").strip()

def clean_navarasa_answer(text):
    if not text:
        return ""
    cleaned = text.strip()
    prefixes = ["ANSWER:", "Answer:", "FINAL ANSWER:", "Final Answer:"]
    for p in prefixes:
        if cleaned.startswith(p):
            cleaned = cleaned[len(p):].strip()
    return cleaned

def build_grounded_context(results):
    if not results:
        return ""
    primary = results[0]
    context_lines = [
        f"PRIMARY SOURCE (Document {primary.get('document_id', 'N/A')}, Section/Type: {primary.get('document_type', 'N/A')}):\n{primary.get('text', '')}"
    ]
    for idx, item in enumerate(results[1:], start=2):
        context_lines.append(
            f"SUPPORTING SOURCE {idx} (Document {item.get('document_id', 'N/A')}, Section/Type: {item.get('document_type', 'N/A')}):\n{item.get('text', '')}"
        )
    return "\n\n".join(context_lines)

def is_complete_answer(text):
    if not text or not text.strip():
        return False
    if text == RAG_FALLBACK:
        return True
    for opening, closing in (("(", ")"), ("[", "]"), ("{", "}")):
        if text.count(opening) != text.count(closing):
            return False
    if text[-1] not in ".!?":
        return False
    return True

def generate_grounded_answer(english_query, results):
    context = build_grounded_context(results)
    if not context:
        return RAG_FALLBACK

    prompt = f"""You are Cooperative Sahayak, a grounded information assistant.

Answer the user's question ONLY using the retrieved source text below.

STRICT GROUNDING RULES:
1. Every factual statement must be directly supported by the retrieved text.
2. Do NOT use pretrained knowledge or outside knowledge.
3. Do NOT guess missing information.
4. Do NOT invent dates, years, Act numbers, section numbers, names,
   institutions, amounts, procedures, or legal claims.
5. Do NOT combine a number or date from one source/chunk with a different
   subject from another source/chunk.
6. PRIMARY SOURCE is the main evidence and should be used first.
7. SUPPORTING SOURCE material may be used only when it directly supports
   the answer.
8. Do not "correct" the source using outside knowledge.
9. Answer directly and concisely in 2–3 complete sentences when the source
   supports that much information.
10. Finish every sentence completely. Never stop after a comma, date, number,
    colon, or other partial phrase.
11. If the retrieved text does not clearly answer the question, output exactly:

Sorry, I couldn't answer your question from the available information.

RETRIEVED SOURCE TEXT:

{context}

USER QUESTION:
{english_query}

ANSWER:
"""

    answer = navarasa_completion(prompt, max_tokens=320, temperature=0.0)
    answer = clean_navarasa_answer(answer)

    if not is_complete_answer(answer):
        retry_prompt = f"""You are Cooperative Sahayak.

Produce a COMPLETE answer to the user's question using ONLY the retrieved
source text.

RULES:
- Use no outside or pretrained knowledge.
- Do not invent or infer facts.
- PRIMARY SOURCE has priority.
- Do not mix unrelated dates, years, Act numbers, or section numbers.
- Give 2–3 complete sentences if supported by the source.
- Finish the answer completely.
- Never end in the middle of a sentence.
- If the source does not clearly answer the question, output exactly:

Sorry, I couldn't answer your question from the available information.

RETRIEVED SOURCE TEXT:

{context}

USER QUESTION:
{english_query}

FINAL ANSWER:
"""
        retry = navarasa_completion(retry_prompt, max_tokens=320, temperature=0.0)
        retry = clean_navarasa_answer(retry)
        if is_complete_answer(retry):
            answer = retry
        else:
            answer = RAG_FALLBACK

    return answer

# ASR (sherpa-onnx) & Tamil Code-Switch
ASR_RECOGNIZERS = {}
ASR_TOKENS_PATH = ASR_BASE_DIR / "tokens.txt"

for lang in ASR_LANGS:
    model_path = ASR_BASE_DIR / lang / "model.int8.onnx"
    ASR_RECOGNIZERS[lang] = sherpa_onnx.OfflineRecognizer.from_nemo_ctc(
        model=str(model_path),
        tokens=str(ASR_TOKENS_PATH),
        num_threads=ASR_NUM_THREADS,
        sample_rate=ASR_SAMPLE_RATE,
        feature_dim=ASR_FEATURE_DIM,
        debug=False,
        provider="cpu",
    )

TAMIL_CODE_SWITCH_MAP = {
    "லோவன்": "loan",
    "லோன்": "loan",
    "ஆப்பிளி": "apply",
    "அப்பிளை": "apply",
    "டோகுமெண்ட்ஸ்": "documents",
    "டாக்குமெண்ட்ஸ்": "documents",
}

def normalize_tamil_code_switch(text):
    if not text:
        return ""
    normalized = str(text).strip()
    for tamil_word, english_word in TAMIL_CODE_SWITCH_MAP.items():
        normalized = normalized.replace(tamil_word, english_word)
    return normalized

def transcribe_audio(audio_data, sample_rate=ASR_SAMPLE_RATE, lang="ta"):
    if lang not in ASR_RECOGNIZERS:
        raise ValueError(f"Unsupported ASR language: {lang}")
    audio_data = np.asarray(audio_data, dtype=np.float32).flatten()
    if audio_data.size == 0:
        return ""
    recognizer = ASR_RECOGNIZERS[lang]
    stream = recognizer.create_stream()
    stream.accept_waveform(sample_rate, audio_data)
    recognizer.decode_stream(stream)
    return stream.result.text.strip()

def transcribe_and_normalize(audio_data, sample_rate, language_code):
    transcription = transcribe_audio(
        audio_data=audio_data,
        sample_rate=sample_rate,
        lang=language_code,
    )
    normalized = transcription
    if language_code == "ta":
        normalized = normalize_tamil_code_switch(transcription)
    return transcription, normalized

# Piper TTS
TTS_MODEL_FILES = {
    "ta": TTS_DIR / "ta_IN-rasa_female-medium.onnx",
    "hi": TTS_DIR / "hi" / "hi_IN" / "priyamvada" / "medium" / "hi_IN-priyamvada-medium.onnx",
    "te": TTS_DIR / "te" / "te_IN" / "venkatesh" / "medium" / "te_IN-venkatesh-medium.onnx",
    "ml": TTS_DIR / "ml" / "ml_IN" / "meera" / "medium" / "ml_IN-meera-medium.onnx",
}

TTS_VOICES = {}
for lang, model_path in TTS_MODEL_FILES.items():
    TTS_VOICES[lang] = PiperVoice.load(str(model_path))

def prepare_tts_text(text):
    if text is None:
        raise ValueError("TTS text is empty.")
    return " ".join(str(text).strip().split())

def synthesize_tts(text, language_code, output_filename=None):
    if language_code not in TTS_VOICES:
        raise ValueError(f"No Piper voice for '{language_code}'.")
    if output_filename is None:
        output_filename = TTS_OUTPUT_DIR / f"tts_{language_code}.wav"
    else:
        output_filename = Path(output_filename)
    output_filename.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_filename), "wb") as wav_file:
        TTS_VOICES[language_code].synthesize_wav(text.strip(), wav_file)
    return output_filename

from pydub import AudioSegment

def decode_audio_bytes_to_float32(audio_bytes, target_sample_rate=ASR_SAMPLE_RATE):
    try:
        seg = AudioSegment.from_file(io.BytesIO(audio_bytes))
        seg = seg.set_frame_rate(target_sample_rate).set_channels(1)
        samples = np.array(seg.get_array_of_samples(), dtype=np.float32)
        if seg.sample_width == 2:
            samples /= 32768.0
        elif seg.sample_width == 4:
            samples /= 2147483648.0
        elif seg.sample_width == 1:
            samples = (samples - 128.0) / 128.0
        return samples
    except Exception as e:
        try:
            data, sr = sf.read(io.BytesIO(audio_bytes), dtype='float32')
            if data.ndim > 1:
                data = data.mean(axis=1)
            if sr != target_sample_rate:
                data = librosa.resample(data, orig_sr=sr, target_sr=target_sample_rate)
            return data
        except Exception:
            data, sr = librosa.load(io.BytesIO(audio_bytes), sr=target_sample_rate, mono=True)
            return data

def run_full_pipeline(audio_bytes, language_code):
    if audio_bytes is None or len(audio_bytes) == 0:
        raise ValueError("Input audio is empty.")
    if language_code not in SUPPORTED_LANGS:
        raise ValueError(f"Unsupported language '{language_code}'. Choose from {SUPPORTED_LANGS}.")

    audio_data = decode_audio_bytes_to_float32(audio_bytes, target_sample_rate=ASR_SAMPLE_RATE)

    native_text, normalized_text = transcribe_and_normalize(
        audio_data=audio_data,
        sample_rate=ASR_SAMPLE_RATE,
        language_code=language_code,
    )

    if not normalized_text.strip():
        raise ValueError("Speech could not be transcribed.")

    english_query = translate_to_english(normalized_text, language_code)
    if not english_query.strip():
        raise ValueError("English translation is empty.")

    retrieved_results = hybrid_search(english_query, top_k=TOP_K, candidate_k=CANDIDATE_K)
    english_answer = generate_grounded_answer(english_query, retrieved_results)
    indic_answer = translate_english_to_indic(english_answer, language_code, max_length=512)

    audio_file = None
    if language_code in TTS_VOICES:
        paced_text = prepare_tts_text(indic_answer)
        out_filename = f"final_spoken_answer_{language_code}_{int(os.urandom(4).hex(), 16)}.wav"
        out_path = TTS_OUTPUT_DIR / out_filename
        audio_file = synthesize_tts(paced_text, language_code, out_path)

    return {
        "input_language": language_code,
        "native_transcription": native_text,
        "normalized_transcription": normalized_text,
        "english_query": english_query,
        "retrieved_results": retrieved_results,
        "english_answer": english_answer,
        "indic_answer": indic_answer,
        "audio_file": str(audio_file) if audio_file else None,
        "audio_filename": audio_file.name if audio_file else None,
    }
