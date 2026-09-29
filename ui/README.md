# 🏛️ Cooperative Sahayak (கூட்டுறவு சகாயக் / सहकारी सहायक)

[![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://python.org)
[![NVIDIA Jetson](https://img.shields.io/badge/Hardware-NVIDIA_Jetson_Orin_Nano-76B900?logo=nvidia&logoColor=white)](https://developer.nvidia.com/embedded/jetson-orin-nano-developer-kit)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Domain-Specific Multilingual AI Voice Kiosk for Indian Cooperative Societies & Governance**

**Cooperative Sahayak** is an offline-capable, voice-first AI Assistant and Kiosk application designed to empower citizens, farmers, and members of Primary Agricultural Credit Societies (PACS) and Multi-State Cooperative Societies. It provides zero-barrier, instant voice access to complex legal, regulatory, operational, and scheme-related information in regional Indian languages.

---

## 📌 Key Highlights

- 🎙️ **Voice-First Accessible Interface**: Touchscreen Kiosk UI with single-tap microphone activation, real-time waveform visualization, and dual visual/audio output.
- 🗣️ **Multilingual Indian Language Support**: Full voice input and spoken output in **Tamil (`ta`)**, **Hindi (`hi`)**, **Telugu (`te`)**, **Kannada (`kn`)**, **Malayalam (`ml`)**, and **English (`en`)**.
- 🧠 **Hybrid Retrieval-Augmented Generation (RAG)**: Combines dense embeddings (FAISS with `bge-small-en-v1.5`) and sparse keyword retrieval (BM25Okapi) over the **Multi-State Cooperative Societies Act (1983, 2002, & 2023 Amendments)**.
- 🔄 **Neural Machine Translation Pipeline**: Utilizes **AI4Bharat IndicTrans2** (`indictrans2-indic-en-1B` & `indictrans2-en-indic-1B`) for bidirectional translation between Indic languages and English.
- 🔊 **Offline Neural Speech Processing**: High-speed offline Speech-to-Text via **Sherpa-ONNX (Indic ASR)** and Text-to-Speech via **Piper ONNX Voice Models**.
- ⚡ **Edge & Kiosk Hardware Ready**: Optimized for deployment on low-power edge hardware including **NVIDIA Jetson Orin Nano 8GB**, Linux Kiosks, macOS, and Android.

---

## 🏗️ System Architecture & AI Pipeline

Cooperative Sahayak operates using a decoupled **Flutter Touchscreen Kiosk Frontend** and a **FastAPI Multi-Stage AI Backend**.

```mermaid
flowchart TD
    subgraph UI ["Flutter Kiosk Frontend (Desktop / Linux / Android)"]
        A[User Selects Language] --> B[Single-Tap Microphone Ask Screen]
        B --> C[Record Native Voice Query WAV]
        C --> D[HTTP Multipart POST /api/process_voice]
        J[Display Native Text Answer] <-- Receive JSON Response -- D
        K[Play Spoken Audio Playback] <-- Stream WAV Audio -- D
    end

    subgraph Backend ["FastAPI AI Pipeline Backend"]
        D --> E[Sherpa-ONNX Indic STT]
        E -->|Native Indic Transcript| F[AI4Bharat IndicTrans2 Indic->EN]
        F -->|English Query| G[Hybrid RAG Engine FAISS + BM25]
        G -->|Retrieved Legal Chunks| H[Llama.cpp LLM Inference]
        H -->|English Legal Answer| I[IndicTrans2 EN->Indic Translation]
        I -->|Native Text Answer| TTS[Piper ONNX TTS Engine]
        TTS -->|Spoken WAV Audio| D
    end
```

---

## 📁 Repository Structure

```
cooperative_sahayak/
├── assets/                  # Offline Noto & Roboto TTF fonts for Indic scripts
│   └── fonts/
├── backend/                 # FastAPI server & AI pipeline
│   ├── main.py              # FastAPI app routes (/api/process_voice, /audio static)
│   └── pipeline.py          # End-to-End inference engine (STT, NMT, RAG, LLM, TTS)
├── lib/                     # Flutter frontend application
│   ├── main.dart            # Kiosk app entrypoint & root widget
│   ├── localization/        # Regional language strings & translations
│   ├── models/              # Kiosk state management (KioskStateNotifier)
│   ├── screens/             # Kiosk screen widgets (Language, Ask, Processing, Answer)
│   ├── services/            # API client (ApiService) & Audio Recorder (AudioRecorderService)
│   ├── theme/               # Kiosk design system & font fallback configuration
│   └── widgets/             # Reusable UI components (Keypad, Frame, Scroll items)
├── android/                 # Android mobile/kiosk platform configuration
├── ios/                     # iOS platform configuration
├── linux/                   # Linux GTK desktop runner
├── macos/                   # macOS desktop runner
├── windows/                 # Windows desktop runner
├── LINUX_DEPLOYMENT.md      # Systemd kiosk setup guide for NVIDIA Jetson Orin Nano
├── pubspec.yaml             # Flutter project dependencies & asset definitions
└── README.md                # Project documentation
```

---

## 🌐 Supported Languages & Typography

The application bundles offline Open Font License (OFL) font families in `assets/fonts/` to ensure text rendering across all supported languages without requiring active internet access or system-installed desktop fonts:

| Language | Code | Bundled Font Family |
|---|---|---|
| **Tamil** | `ta` | `NotoSansTamil` |
| **Hindi** | `hi` | `NotoSansDevanagari` |
| **Telugu** | `te` | `NotoSansTelugu` |
| **Kannada** | `kn` | `NotoSansKannada` |
| **Malayalam** | `ml` | `NotoSansMalayalam` |
| **English** | `en` | `Roboto` / `NotoSerif` |

---

## 🚀 Quick Start Guide

### 1. Prerequisites

- **Flutter SDK**: `^3.9.0`
- **Python**: `3.11+`
- **FastAPI / Uvicorn**
- Required backend Python packages: `torch`, `transformers`, `sherpa-onnx`, `piper-tts`, `faiss-cpu`, `rank_bm25`, `IndicTransToolkit`, `librosa`, `soundfile`, `requests`.

### 2. Setting Up & Running the FastAPI Backend

1. **Activate Python Environment**:
   ```bash
   cd backend
   # Activate your virtualenv containing backend models & packages
   source /path/to/your_env/bin/activate
   ```

2. **Start the FastAPI Server**:
   ```bash
   python main.py
   ```
   *The server runs at `http://0.0.0.0:8000`. You can inspect the health check at `http://127.0.0.1:8000/`.*

### 3. Setting Up & Running the Flutter App

1. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on macOS / Desktop**:
   ```bash
   flutter run -d macOS
   ```

3. **Run on Linux Desktop**:
   ```bash
   flutter run -d linux
   ```

---

## 📡 API Specification

### `POST /api/process_voice`

Processes an incoming audio file with the selected language code through the AI pipeline.

#### Request (Multipart Form Data):
- `language` (string, required): Language code (`ta`, `hi`, `te`, `kn`, `ml`, `en`).
- `audio` (file, required): Recorded WAV/MP3 voice query file.

#### Response (`200 OK` JSON):
```json
{
  "status": "success",
  "language": "ta",
  "transcription": "பல மாநில கூட்டுறவு சங்கங்கள் சட்டம் என்றால் என்ன",
  "native_transcription": "பல மாநில கூட்டுறவு சங்கங்கள் சட்டம் என்றால் என்ன",
  "english_query": "What is the Multi-State Cooperative Societies Act?",
  "english_answer": "The Multi-State Cooperative Societies Act is an Act of Parliament...",
  "answer_native": "பல மாநில கூட்டுறவு சங்கங்கள் சட்டம் என்பது...",
  "audio_url": "http://127.0.0.1:8000/audio/final_spoken_answer_ta_1813487817.wav"
}
```

---

## 🖥️ Edge & Kiosk Deployment (NVIDIA Jetson Orin Nano)

For standalone deployment in Primary Agricultural Credit Societies (PACS) or rural banking kiosks using **NVIDIA Jetson Orin Nano 8GB** running JetPack Linux:

1. Install GTK & GStreamer development packages:
   ```bash
   sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libgstreamer1.0-dev libpulse-dev libasound2-dev
   ```
2. Build ARM64 production binary:
   ```bash
   flutter build linux --release
   ```
3. Refer to [**LINUX_DEPLOYMENT.md**](LINUX_DEPLOYMENT.md) for full `systemd` autostart kiosk instructions.

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
