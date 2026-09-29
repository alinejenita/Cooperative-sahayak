# Multilingual Cooperative Governance & Legal Assistance Kiosk

> **AI-Enabled Multilingual Cooperative Assistance & Services Kiosk**  
> Smart India Hackathon 2026 | Problem Statement 26088 | Ministry of Cooperation / NCCT

## 🎥 Demonstration

[![Watch the Kiosk Demonstration](https://img.youtube.com/vi/2XeNBqoLlXQ/maxresdefault.jpg)](https://www.youtube.com/watch?v=2XeNBqoLlXQ)

**Click the image above to watch the demonstration on YouTube.**

> GitHub README files do not support autoplaying YouTube videos directly. The thumbnail above acts as a clickable video preview.

## Overview

A multilingual, offline-first AI kiosk designed to provide cooperative members with accessible information and services through voice and touch interaction.

### Primary Service Paths

- **Query & Information:** Cooperative schemes, laws, guidelines, eligibility, FAQs and related information through a RAG-based assistant.
- **Account / Ledger Services:** Authenticated access to member account or ledger information through authorized cooperative/bank APIs.

## Key Features

- Multilingual voice interaction
- Touch-based interaction
- AI4Bharat Indic ASR
- Hybrid RAG retrieval using keyword and semantic search
- Local LLM inference with Navarasa 2.0
- On-device text-to-speech
- Offline-first operation
- KCC-based member/account identification
- PIN-based authentication
- Authorized cooperative/bank API integration
- Local knowledge base for schemes, laws, guidelines and FAQs
- Voice + display responses

## System Flow

```text
Voice Input / Touch Input
          ↓
   Speech-to-Text (ASR)
          ↓
     ┌────┴────┐
     ↓         ↓
   RAG Flow   Account / Ledger Flow
     ↓         ↓
     └────┬────┘
          ↓
   Response Generation
          ↓
      Text-to-Speech
          ↓
   Voice + Display Output
```

## Technology Stack

| Component | Technology |
|---|---|
| Speech Recognition | AI4Bharat IndicConformer |
| Retrieval | BM25 + Multilingual Embeddings |
| Vector Search | FAISS |
| LLM | Navarasa 2.0 (Indic-Gemma-2B) |
| Local Inference | llama-server / llama.cpp |
| Text-to-Speech | Indic TTS / Piper runtime |
| Hardware | NVIDIA Jetson Orin Nano, touch display, microphone, speaker, KCC/smart-card reader |

## RAG Pipeline

```text
User Query
    ↓
BM25 + Multilingual Embeddings
    ↓
Hybrid Retrieval / RRF
    ↓
Relevant Knowledge Context
    ↓
Grounded Prompt
    ↓
Navarasa 2.0
    ↓
Response
```

The information assistant is designed to answer from retrieved knowledge rather than unrestricted external knowledge.

## Account / Ledger Flow

```text
KCC Card
   ↓
PIN Authentication
   ↓
Authorized Cooperative / Bank API
   ↓
Account / Ledger Information
   ↓
Response
```

Live member financial information is obtained through an authorized cooperative/bank backend API. The National Cooperative Database is treated as a cooperative-information source, not as an assumed source of individual account balances.

## Offline-First Design

Core AI functions are designed to run locally:

- Speech recognition
- Retrieval
- LLM inference
- Text-to-speech
- Knowledge-base access

Internet connectivity is used when required for live account information, authorized backend services, synchronization, or secure updates.

## Security & Privacy

- KCC + PIN authentication for member services
- Authorized API access for live account information
- Minimal local retention of sensitive member information
- Encrypted backend communication
- Controlled access to account/ledger services

## Team

### The Final Iteration

Built for **Smart India Hackathon 2026**.

## Demo Video

https://www.youtube.com/watch?v=2XeNBqoLlXQ

---

## License

Add the applicable project license before publishing.
