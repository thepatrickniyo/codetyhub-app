# CodetyHub Node Bridge

Express.js API gateway between Node.js consumers and the CodetyHub FastAPI ML microservice.

## Quick Start

```bash
cd node-bridge
npm install
cp .env.example .env    # Edit ML_API_URL if needed
npm run dev             # Starts on port 3001 with nodemon
```

## Prerequisites
- Node.js ≥ 18
- The FastAPI ML service running on `ML_API_URL` (default: `http://localhost:8000`)

## API Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/pathway/recommend` | ✅ | Hybrid pathway recommendation |
| GET  | `/api/pathway/graph/info` | ❌ | Knowledge graph statistics |
| GET  | `/api/pathway/graph/prerequisites/:skillId` | ❌ | Prerequisite lookup |
| POST | `/api/gamification/risk` | ✅ | Dropout risk prediction |
| POST | `/api/gamification/batch` | ✅ | Batch risk (daily pipeline) |
| GET  | `/api/gamification/features` | ❌ | 34 feature catalogue |
| POST | `/api/code-review/evaluate` | ✅ | CodeBERT VSS evaluation |
| GET  | `/api/code-review/leaderboard` | 〜 | VSS leaderboard (public) |
| GET  | `/api/code-review/rubric` | ❌ | Rubric & weights |

## Auth

Pass a `Bearer <token>` in the `Authorization` header for protected routes.
The `auth.js` middleware stub accepts any non-empty token in development.
Replace `verifyToken()` with a real `jwt.verify()` call in production.

## Example Request

```bash
curl -X POST http://localhost:3001/api/pathway/recommend \
  -H "Authorization: Bearer dev-token" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU-1042",
    "ikp": {
      "proficiency_scores": {
        "python_basics": 0.90,
        "data_types": 0.85,
        "linear_regression": 0.20
      }
    },
    "top_n": 5
  }'
```
