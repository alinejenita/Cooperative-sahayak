# SarVani - Multilingual Cooperative Assistance & Services Kiosk

> **AI-Powered Multilingual Cooperative Member Services & Legal Assistance Kiosk**  
> Smart India Hackathon 2026 | Problem Statement **SIH26088** | Theme: **Agriculture, FoodTech & Rural Development** | Category: **Hardware**  
> Team: **The Final Iteration** | Team ID: **126745**

## 🎥 Demonstration

[![Watch the Kiosk Demonstration](https://img.youtube.com/vi/2XeNBqoLlXQ/maxresdefault.jpg)](https://www.youtube.com/watch?v=2XeNBqoLlXQ)

**Click the image above to watch the demonstration on YouTube.**

## Overview

**SarVani** is a multilingual, voice-first AI kiosk for PACS offices and cooperative societies. A member chooses a language, speaks a question, and receives a spoken and written answer.

The system is designed for cooperative schemes, services, financial information, legal guidance and grievance/redressal procedures, with a separate authenticated account and ledger service path.

### Supported Interaction

- Speech input and output: **Tamil, Hindi, Telugu and Malayalam**
- Text support: **Kannada and English**
- Voice-first interaction with touch as a secondary input
- Large on-screen text with audio responses

### Primary Service Paths

- **Query & Information:** Cooperative schemes, laws, guidelines, eligibility, FAQs, financial-literacy information and grievance/redressal guidance through a grounded RAG assistant.
- **Account / Ledger Services:** KCC-based authenticated access to member account or ledger information through an authorized cooperative/bank API.

## Key Features

- Multilingual voice interaction
- Voice-first kiosk interface
- AI4Bharat Indic ASR
- Hybrid RAG using **BM25 keyword retrieval + FAISS multilingual semantic retrieval**
- Local LLM inference with **Navarasa 2.0 (Indic-Gemma-2B)**
- On-device text-to-speech using **Piper Indic TTS**
- Offline-first core AI operation
- KCC-based member/account identification
- PIN-based authentication
- Authorized cooperative/bank API integration
- Local knowledge base for schemes, laws, guidelines and FAQs
- Voice + display responses
- Tamil-English code-switch handling

## System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    1. KIOSK DEVICE                          │
│                 NVIDIA Jetson Orin Nano 8GB                 │
│                                                             │
│  Mic ──┐                                                    │
│        ├──> ASR ──> Translation / Normalisation ──┐         │
│ Touch ─┘                                          │         │
│                                                   ↓         │
│                              ┌──────────────────────────┐   │
│                              │ Local AI / RAG Services  │   │
│                              │ BM25 + FAISS + Navarasa  │   │
│                              │ + Piper TTS              │   │
│                              └────────────┬─────────────┘   │
│                                           │                 │
│                              Voice + Display Response       │
└───────────────────────────────┬─────────────────────────────┘
                                │ REST / JSON
                                ↓
┌─────────────────────────────────────────────────────────────┐
│                 2. LOCAL BACKEND / AI SERVICES              │
│                                                             │
│  RAG Service       LLM Service       Translation Service    │
│  Session & Access Control                                   │
└───────────────┬─────────────────────────────────┬───────────┘
                │ Local File Access               │ HTTPS / JSON
                ↓                                 ↓
┌──────────────────────────┐       ┌──────────────────────────┐
│ 3. LOCAL STORAGE         │       │ 4. EXTERNAL SYSTEMS      │
│                          │       │                          │
│ Policy / scheme docs     │       │ Authorized Cooperative / │
│ Acts / bye-laws          │       │ Bank API                 │
│ RAG index                │       │ Account / ledger data    │
│ Model files              │       │                          │
│ Non-PII logs             │       │ Connectivity required    │
└──────────────────────────┘       └──────────────────────────┘
```

## Hardware

- **NVIDIA Jetson Orin Nano 8GB** - prototype compute platform
- **13.3-inch capacitive touch display**
- **ReSpeaker far-field microphone array**
- **USB speaker**
- **KCC / smart-card reader** for the authenticated service flow
- A **3D-printed scaled-down kiosk model** has been built to demonstrate the physical layout of the display, speaker and microphone.

## Technology Stack

| Component | Technology |
|---|---|
| Speech Recognition | AI4Bharat IndicConformer / Indic ASR |
| Translation | Indic language translation / code-switch normalisation |
| Retrieval | BM25 keyword + multilingual embeddings |
| Vector Search | FAISS |
| Retrieval Fusion | Reciprocal Rank Fusion (RRF) |
| LLM | Navarasa 2.0 (Indic-Gemma-2B) |
| Local Inference | llama-server / llama.cpp |
| Text-to-Speech | Indic TTS / Piper runtime |
| Frontend | Flutter |
| Hardware | NVIDIA Jetson Orin Nano 8GB, touch display, ReSpeaker mic array, speaker |

## RAG Pipeline

```text
User Query
    ↓
Speech-to-Text
    ↓
Query Normalisation / Translation
    ↓
BM25 Keyword Retrieval + FAISS Semantic Retrieval
    ↓
RRF / Candidate Selection
    ↓
Relevant Knowledge Context
    ↓
Grounded Source-Only Prompt
    ↓
Navarasa 2.0
    ↓
Response
    ↓
Indic TTS
    ↓
Voice + Display Output
```

The information assistant is designed to answer from retrieved knowledge rather than unrestricted external knowledge.

### Grounding & Fallback

- Source-only prompting
- **0.45 similarity cutoff**
- Safe fallback when sufficient supporting context is not available
- Retrieval designed for both exact legal terminology and semantic paraphrases
- Knowledge sources are maintained as a local, version-controlled corpus

## Knowledge Sources

The current information assistant is designed around official cooperative, scheme and legal material, including:

- MSCS Acts
- PACS Model Bye-laws 2023
- National Cooperative Policy
- PMFBY
- PM-KISAN

The production knowledge base should use verified, versioned official sources and controlled updates.

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

Live member financial information is obtained through an authorized cooperative/bank backend API.

The **National Cooperative Database is treated as a cooperative-information source, not as an assumed source of individual account balances or transactions.**

## Offline-First Design

Core AI functions are designed to run locally:

- Speech recognition
- Retrieval
- LLM inference
- Text-to-speech
- Local knowledge-base access
- Query processing and response generation

Internet connectivity is required when the kiosk needs:

- Live account / ledger information
- Authorized cooperative or bank backend services
- Synchronization
- Controlled knowledge/model updates

Therefore, SarVani is **offline-first**, not a claim of zero-connectivity operation for every service.

## Security & Privacy

- KCC + PIN authentication for the account/ledger service
- Authorized API access for live account information
- Minimal local retention of sensitive member information
- Encrypted backend communication
- Controlled access to account/ledger services
- Version-controlled knowledge sources
- No assumption that the National Cooperative Database provides individual financial transactions

## Prototype Status

- End-to-end local AI prototype is working.
- A scaled 3D-printed kiosk model has been built.
- Local ASR, retrieval, LLM inference and TTS components have been integrated.
- KCC-based authenticated account/ledger flow is designed around an authorized cooperative/bank API.
- Prototype hardware estimate: **₹69,500–₹84,000 per kiosk**.

## Government Digital Context

The Government of India's PACS computerisation programme provides the digital ecosystem that SarVani is designed to interface with.

- **79,630 PACS** sanctioned for computerisation across 31 States/UTs.
- **63,707 PACS** onboarded on the ERP-based national software as of **5 August 2026**.
- Revised financial outlay: **₹2,925.39 crore**.
- Approximately **32 crore cooperative members** are represented in the National Cooperative Database across 30 sectors.

These figures describe the broader cooperative digital ecosystem, **not SarVani deployment numbers**.

SarVani is designed as a **multilingual AI interface layer** that can work with this existing cooperative digital ecosystem.

## Impact

### For Members

- Accessible self-service through regional-language voice interaction
- Reduced dependence on complex digital interfaces
- Faster access to scheme, cooperative and legal information
- Authenticated access to account and ledger information through authorized services

### For Cooperatives

- Routine information enquiries can be handled through self-service
- Staff can focus on higher-value cooperative operations
- A common voice-first interface can support members across languages

### For the Digital Ecosystem

**Existing Government digital infrastructure + Local AI interface = accessible last-mile cooperative services**

## Feasibility & Viability

### Key Challenges

**Voice Recognition**
- Noise, accents and dialects may reduce ASR accuracy.
- Mitigation: far-field microphone, regional tuning and confidence-based handling.

**Legal Accuracy**
- Outdated or incorrect information can produce unreliable responses.
- Mitigation: verified legal sources, versioned legal RAG and regular controlled updates.

### Proposed Rollout

```text
Prototype
   ↓
PACS Testing
   ↓
District Pilot
   ↓
State Scale
```

Deployment phases are proposed rollout stages, not current deployment claims.

## Cost

Estimated one-time prototype hardware cost per kiosk:

**₹69,500–₹84,000**

The estimate covers the prototype compute module and peripherals. Actual procurement cost may vary by hardware configuration and deployment requirements.

## Team

### The Final Iteration

**Team ID:** 126745

Built for **Smart India Hackathon 2026**.

## References

- Ministry of Cooperation, Government of India - PACS computerisation programme
- IITG-INDIGO - Multilingual & Code-Switching ASR
- *Towards Building Text-to-Speech Systems for the Next Billion Users*, IEEE ICASSP 2023
- *Retrieval Augmented Generation Based Question Answering System on Policy Documents*
- *From Courts to Comprehension: Can LLMs Make Judgments More Accessible?*, IEEE/WI-IAT 2024
- *AI-Powered Offline Voice Assistant for Rural Communities*, IEEE ICIDCA 2025

## Demo Video

https://www.youtube.com/watch?v=2XeNBqoLlXQ

---


