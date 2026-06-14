import '../models/quiz_model.dart';

/// 10 adaptive placement questions.
///
/// Every answer awards weighted points to one or more pathway IDs.
/// The pathway with the highest total score at the end is recommended.
///
/// Pathway IDs:
///   ml-fundamentals | deep-learning | nlp | computer-vision | generative-ai | mlops
class QuizData {
  QuizData._();

  static const List<QuizQuestion> questions = [
    // ── Q1: Programming background ───────────────────────────────────────────
    QuizQuestion(
      question: 'How confident are you with Python programming?',
      hint: 'Be honest — there are no wrong answers here.',
      options: [
        'I have never written code before',
        'I know basic syntax but struggle with projects',
        'I can build scripts and small applications',
        'I am comfortable with libraries and packages',
      ],
      optionScores: [
        {'ml-fundamentals': 0, 'deep-learning': 0, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 0},
        {'ml-fundamentals': 1, 'deep-learning': 0, 'nlp': 1, 'computer-vision': 0, 'generative-ai': 2, 'mlops': 0},
        {'ml-fundamentals': 2, 'deep-learning': 1, 'nlp': 2, 'computer-vision': 1, 'generative-ai': 2, 'mlops': 2},
        {'ml-fundamentals': 3, 'deep-learning': 2, 'nlp': 2, 'computer-vision': 2, 'generative-ai': 2, 'mlops': 3},
      ],
    ),

    // ── Q2: Math comfort ─────────────────────────────────────────────────────
    QuizQuestion(
      question: 'Which math area do you feel most comfortable with?',
      hint: 'This helps us gauge the right starting depth.',
      options: [
        'Statistics and probability',
        'Linear algebra and matrices',
        'Language, logic, and linguistics',
        'Geometry and spatial reasoning',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 2},
        {'ml-fundamentals': 1, 'deep-learning': 3, 'nlp': 1, 'computer-vision': 2, 'generative-ai': 1, 'mlops': 1},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 3, 'computer-vision': 0, 'generative-ai': 2, 'mlops': 0},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 0, 'computer-vision': 3, 'generative-ai': 1, 'mlops': 0},
      ],
    ),

    // ── Q3: Data type preference ─────────────────────────────────────────────
    QuizQuestion(
      question: 'What kind of data do you most enjoy working with?',
      hint: 'The type of data often determines the best learning path.',
      options: [
        'Numbers and structured spreadsheets',
        'Text, articles, and language',
        'Photos, videos, and visual content',
        'A mix of everything',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 1, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 2},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 3, 'computer-vision': 0, 'generative-ai': 2, 'mlops': 0},
        {'ml-fundamentals': 0, 'deep-learning': 2, 'nlp': 0, 'computer-vision': 3, 'generative-ai': 1, 'mlops': 0},
        {'ml-fundamentals': 1, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 1, 'generative-ai': 3, 'mlops': 1},
      ],
    ),

    // ── Q4: Dream AI project ─────────────────────────────────────────────────
    QuizQuestion(
      question: 'If you could build any AI project right now, what would it be?',
      hint: 'Think about what excites you most about artificial intelligence.',
      options: [
        'A system that predicts outcomes from historical data',
        'A chatbot or AI writing assistant',
        'An app that identifies objects in photos or videos',
        'A tool that generates art, music, or creative content',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 1, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 0, 'mlops': 2},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 3, 'computer-vision': 0, 'generative-ai': 2, 'mlops': 0},
        {'ml-fundamentals': 0, 'deep-learning': 2, 'nlp': 0, 'computer-vision': 3, 'generative-ai': 0, 'mlops': 1},
        {'ml-fundamentals': 0, 'deep-learning': 2, 'nlp': 1, 'computer-vision': 0, 'generative-ai': 3, 'mlops': 0},
      ],
    ),

    // ── Q5: AI term recognition ──────────────────────────────────────────────
    QuizQuestion(
      question: 'How familiar are you with "transformer models" in AI?',
      hint: 'Transformers power tools like ChatGPT, DALL-E, and more.',
      options: [
        'Never heard of them',
        'I have heard the term but cannot explain it',
        'I understand the concept of attention mechanisms',
        'I can explain self-attention and encoder-decoder architecture',
      ],
      optionScores: [
        {'ml-fundamentals': 1, 'deep-learning': 0, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 0, 'mlops': 0},
        {'ml-fundamentals': 1, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 0},
        {'ml-fundamentals': 1, 'deep-learning': 2, 'nlp': 2, 'computer-vision': 1, 'generative-ai': 2, 'mlops': 1},
        {'ml-fundamentals': 1, 'deep-learning': 3, 'nlp': 3, 'computer-vision': 1, 'generative-ai': 3, 'mlops': 2},
      ],
    ),

    // ── Q6: Career goal ──────────────────────────────────────────────────────
    QuizQuestion(
      question: 'Which career title resonates with you the most?',
      hint: 'This helps align your pathway to industry roles.',
      options: [
        'Machine Learning Engineer or Data Scientist',
        'Conversational AI or NLP Engineer',
        'Computer Vision or Robotics Engineer',
        'AI Product Builder or Prompt Engineer',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 2, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 0, 'mlops': 3},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 3, 'computer-vision': 0, 'generative-ai': 2, 'mlops': 1},
        {'ml-fundamentals': 0, 'deep-learning': 2, 'nlp': 0, 'computer-vision': 3, 'generative-ai': 0, 'mlops': 1},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 0, 'generative-ai': 3, 'mlops': 1},
      ],
    ),

    // ── Q7: Tools used before ────────────────────────────────────────────────
    QuizQuestion(
      question: 'Which of these tools have you actively used?',
      hint: 'Select the option that best represents your toolkit.',
      options: [
        'Pandas, NumPy, or Scikit-learn',
        'TensorFlow or PyTorch',
        'OpenAI API, Hugging Face, or LangChain',
        'Docker, Kubernetes, or cloud platforms (AWS, GCP)',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 1, 'generative-ai': 0, 'mlops': 2},
        {'ml-fundamentals': 1, 'deep-learning': 3, 'nlp': 1, 'computer-vision': 2, 'generative-ai': 1, 'mlops': 1},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 2, 'computer-vision': 0, 'generative-ai': 3, 'mlops': 1},
        {'ml-fundamentals': 1, 'deep-learning': 0, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 3},
      ],
    ),

    // ── Q8: Learning style ───────────────────────────────────────────────────
    QuizQuestion(
      question: 'How do you prefer to learn a new AI concept?',
      hint: 'Knowing your style helps us pick the right pathway structure.',
      options: [
        'Reading theory then applying it on real datasets',
        'Building small projects from scratch immediately',
        'Experimenting with pre-trained models and APIs',
        'Following structured step-by-step deployment guides',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 2, 'nlp': 1, 'computer-vision': 1, 'generative-ai': 0, 'mlops': 1},
        {'ml-fundamentals': 1, 'deep-learning': 3, 'nlp': 1, 'computer-vision': 3, 'generative-ai': 1, 'mlops': 2},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 2, 'computer-vision': 1, 'generative-ai': 3, 'mlops': 1},
        {'ml-fundamentals': 1, 'deep-learning': 1, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 3},
      ],
    ),

    // ── Q9: Production importance ────────────────────────────────────────────
    QuizQuestion(
      question: 'How important is deploying your ML models to real users?',
      hint: 'This gauges your interest in engineering versus research.',
      options: [
        'Not yet — I want to learn the fundamentals first',
        'Somewhat — I want to understand the basics of deployment',
        'Very important — I need production-ready skills',
        'It is my primary focus right now',
      ],
      optionScores: [
        {'ml-fundamentals': 2, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 1, 'generative-ai': 1, 'mlops': 0},
        {'ml-fundamentals': 1, 'deep-learning': 1, 'nlp': 1, 'computer-vision': 1, 'generative-ai': 1, 'mlops': 2},
        {'ml-fundamentals': 0, 'deep-learning': 0, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 1, 'mlops': 3},
        {'ml-fundamentals': 0, 'deep-learning': 0, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 0, 'mlops': 3},
      ],
    ),

    // ── Q10: Concept excitement ───────────────────────────────────────────────
    QuizQuestion(
      question: 'Which AI concept sounds the most exciting to explore?',
      hint: 'Your curiosity is the strongest signal of the right fit.',
      options: [
        'Decision Trees, Random Forests, and gradient boosting',
        'Backpropagation, CNNs, and training from scratch',
        'Word embeddings, sentiment analysis, and language models',
        'Diffusion models, GANs, and prompt engineering',
      ],
      optionScores: [
        {'ml-fundamentals': 3, 'deep-learning': 1, 'nlp': 0, 'computer-vision': 0, 'generative-ai': 0, 'mlops': 2},
        {'ml-fundamentals': 1, 'deep-learning': 3, 'nlp': 0, 'computer-vision': 3, 'generative-ai': 1, 'mlops': 0},
        {'ml-fundamentals': 0, 'deep-learning': 1, 'nlp': 3, 'computer-vision': 0, 'generative-ai': 2, 'mlops': 0},
        {'ml-fundamentals': 0, 'deep-learning': 2, 'nlp': 1, 'computer-vision': 0, 'generative-ai': 3, 'mlops': 0},
      ],
    ),
  ];
}
