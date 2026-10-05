import os
import sys
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Ensure current directory is in python path
sys.path.insert(0, str(Path(__file__).parent.resolve()))

import pipeline

app = FastAPI(
    title="SarVani Notebook Inference API",
    version="1.0.0",
)

# Enable CORS for local Flutter UI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve TTS output directory static audio files
TTS_OUTPUT_DIR = pipeline.TTS_OUTPUT_DIR
app.mount("/audio", StaticFiles(directory=str(TTS_OUTPUT_DIR)), name="audio")

@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": "SarVani Notebook Pipeline Backend",
        "supported_languages": pipeline.SUPPORTED_LANGS,
    }

@app.post("/api/process_voice")
async def process_voice(
    request: Request,
    language: str = Form(...),
    audio: UploadFile = File(...),
):
    try:
        lang_code = language.strip().lower()
        if lang_code not in pipeline.SUPPORTED_LANGS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported language '{lang_code}'. Supported languages: {pipeline.SUPPORTED_LANGS}",
            )

        audio_bytes = await audio.read()
        if not audio_bytes or len(audio_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty audio file provided.")

        result = pipeline.run_full_pipeline(
            audio_bytes=audio_bytes,
            language_code=lang_code,
        )

        # Build absolute or relative URL for generated audio file
        audio_url = None
        if result.get("audio_filename"):
            base_url = str(request.base_url).rstrip("/")
            audio_url = f"{base_url}/audio/{result['audio_filename']}"

        return JSONResponse(
            content={
                "status": "success",
                "language": result["input_language"],
                "transcription": result["normalized_transcription"],
                "native_transcription": result["native_transcription"],
                "english_query": result["english_query"],
                "english_answer": result["english_answer"],
                "answer_native": result["indic_answer"],
                "audio_url": audio_url,
            }
        )

    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
