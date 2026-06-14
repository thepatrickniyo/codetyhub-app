# CodetyHub Monorepo

CodetyHub is a personalized AI-assisted STEM learning platform featuring a Flutter mobile app client, a Python FastAPI Machine Learning microservice, and a Node.js API Gateway bridge.

---

## Repository Structure

```
codetyhub-app/
├── app/                          ← Flutter mobile client
│   ├── lib/                      ← Dart codebase (GetX state, views, controllers)
│   ├── pubspec.yaml              ← Dependencies (GetX, GetStorage, etc.)
│   └── ...
│
├── ML/                           ← Python ML Infrastructure
│   ├── api/                      ← FastAPI endpoint routers & schemas
│   ├── knowledge_graph/          ← NetworkX DAG & curriculum prerequisite lookup
│   ├── recommendation/           ← Collaborative filtering engine (scikit-learn SVD)
│   ├── gamification/             ← Behavioural dropout risk predictor (XGBoost)
│   ├── code_review/              ← Verified Skill Score (VSS) evaluator (CodeBERT)
│   ├── data/                     ← 200 synthetic student profiles generator
│   └── requirements.txt          ← Python dependencies
│
└── node-bridge/                  ← Node.js API Gateway Bridge
    ├── src/                      ← Express app with validation and JWT stub
    ├── package.json              ← Node.js dependencies (Express, Axios, Morgan)
    └── .env.example              ← Environment template
```

---

## Module Overview & Quick Start

### 1. Python ML Microservice (`ML/`)
The ML microservice houses the curriculum Knowledge Graph DAG, the SVD Collaborative Filter recommendation engine, the XGBoost dropout risk predictor, and the CodeBERT evaluation pipeline.

#### Quick Start:
```bash
# From the repository root, set up and activate the virtual environment:
python3 -m venv venv
source venv/bin/activate

# Install requirements:
pip install -r ML/requirements.txt

# Run uvicorn server:
uvicorn ML.api.main:app --reload --port 8000
```
- **Interactive Swagger Docs:** http://localhost:8000/docs

---

### 2. Node.js Express Bridge (`node-bridge/`)
Exposes REST endpoints to client applications, handles JWT stub verification, validates request parameters, and proxies requests to the ML microservice.

#### Quick Start:
```bash
# Go to the bridge directory and install packages:
cd node-bridge
npm install

# Copy env template and start the dev server:
cp .env.example .env
npm run dev
```
- **Local Dev Server:** http://localhost:3001
- **Available routes:**
  - `POST /api/pathway/recommend`
  - `GET  /api/pathway/graph/info`
  - `GET  /api/pathway/graph/prerequisites/:skillId`
  - `POST /api/gamification/risk`
  - `POST /api/gamification/batch`
  - `GET  /api/gamification/features`
  - `POST /api/code-review/evaluate`
  - `GET  /api/code-review/leaderboard`
  - `GET  /api/code-review/rubric`

---

### 3. Flutter Client App (`app/`)
The learning pathway companion client. Tap pathways, track courses, submit assignments, and view talent leaderboards.

#### Quick Start:
```bash
cd app
flutter pub get
flutter run
```

---

## Verification & Testing

To run the full end-to-end integration and API verification suite:
```bash
./venv/bin/python .gemini/antigravity/brain/1ce0d452-f35f-40dc-8f39-e8c785dba971/scratch/verify_system.py
```
This runs both the FastAPI and Node.js Express bridge services, executes verification checks against all 12 API endpoints, and clean terminates the servers.

