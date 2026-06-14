import '../models/course_model.dart';
import '../models/leaderboard_model.dart';
import '../models/pathway_model.dart';

class MockData {
  MockData._();

  static const List<LeaderboardEntry> leaderboard = [
    LeaderboardEntry(
      rank: 1,
      name: 'Aisha Kamara',
      avatarInitials: 'AK',
      points: 12480,
      pathwaysCompleted: 5,
      streak: 34,
    ),
    LeaderboardEntry(
      rank: 2,
      name: 'Marcus Chen',
      avatarInitials: 'MC',
      points: 11950,
      pathwaysCompleted: 4,
      streak: 28,
    ),
    LeaderboardEntry(
      rank: 3,
      name: 'Sofia Rivera',
      avatarInitials: 'SR',
      points: 10740,
      pathwaysCompleted: 4,
      streak: 21,
    ),
    LeaderboardEntry(
      rank: 4,
      name: 'James Osei',
      avatarInitials: 'JO',
      points: 9860,
      pathwaysCompleted: 3,
      streak: 15,
    ),
    LeaderboardEntry(
      rank: 5,
      name: 'Priya Nair',
      avatarInitials: 'PN',
      points: 8920,
      pathwaysCompleted: 3,
      streak: 12,
    ),
  ];

  static const List<PathwayModel> pathways = [
    PathwayModel(
      id: 'ml-fundamentals',
      title: 'Machine Learning Fundamentals',
      description:
          'Build a solid foundation in ML algorithms, data preprocessing, and model evaluation.',
      icon: 'ml-fundamentals',
      colorIndex: 0,
      totalHours: 24,
      courses: [
        CourseModel(
          id: 'ml-1',
          title: 'Introduction to Machine Learning',
          description:
              'Understand supervised vs unsupervised learning and the ML workflow.',
          duration: '3h 20m',
          level: 'Beginner',
          lessons: 12,
          rating: 4.8,
        ),
        CourseModel(
          id: 'ml-2',
          title: 'Linear & Logistic Regression',
          description:
              'Master regression techniques for prediction and classification tasks.',
          duration: '4h 10m',
          level: 'Beginner',
          lessons: 15,
          rating: 4.7,
        ),
        CourseModel(
          id: 'ml-3',
          title: 'Decision Trees & Random Forests',
          description:
              'Learn ensemble methods that power many real-world ML systems.',
          duration: '3h 45m',
          level: 'Intermediate',
          lessons: 14,
          rating: 4.9,
        ),
        CourseModel(
          id: 'ml-4',
          title: 'Model Evaluation & Tuning',
          description:
              'Cross-validation, hyperparameter tuning, and avoiding overfitting.',
          duration: '2h 55m',
          level: 'Intermediate',
          lessons: 10,
          rating: 4.6,
        ),
      ],
    ),
    PathwayModel(
      id: 'deep-learning',
      title: 'Deep Learning',
      description:
          'Dive into neural networks, backpropagation, and modern deep learning architectures.',
      icon: 'deep-learning',
      colorIndex: 1,
      totalHours: 32,
      courses: [
        CourseModel(
          id: 'dl-1',
          title: 'Neural Network Basics',
          description:
              'Perceptrons, activation functions, and the fundamentals of deep learning.',
          duration: '4h 30m',
          level: 'Intermediate',
          lessons: 16,
          rating: 4.9,
        ),
        CourseModel(
          id: 'dl-2',
          title: 'Convolutional Neural Networks',
          description:
              'Build CNNs for image classification and object detection.',
          duration: '5h 15m',
          level: 'Intermediate',
          lessons: 18,
          rating: 4.8,
        ),
        CourseModel(
          id: 'dl-3',
          title: 'Recurrent Neural Networks',
          description:
              'LSTMs and GRUs for sequence modeling and time series prediction.',
          duration: '4h 00m',
          level: 'Advanced',
          lessons: 14,
          rating: 4.7,
        ),
        CourseModel(
          id: 'dl-4',
          title: 'Transformers Architecture',
          description:
              'Attention mechanisms and the architecture behind modern AI.',
          duration: '6h 20m',
          level: 'Advanced',
          lessons: 20,
          rating: 4.9,
        ),
      ],
    ),
    PathwayModel(
      id: 'nlp',
      title: 'Natural Language Processing',
      description:
          'Process and understand human language with modern NLP techniques.',
      icon: 'nlp',
      colorIndex: 2,
      totalHours: 28,
      courses: [
        CourseModel(
          id: 'nlp-1',
          title: 'Text Preprocessing & Tokenization',
          description:
              'Clean, tokenize, and prepare text data for NLP pipelines.',
          duration: '2h 40m',
          level: 'Beginner',
          lessons: 11,
          rating: 4.6,
        ),
        CourseModel(
          id: 'nlp-2',
          title: 'Word Embeddings & Word2Vec',
          description:
              'Represent words as dense vectors for semantic understanding.',
          duration: '3h 30m',
          level: 'Intermediate',
          lessons: 13,
          rating: 4.7,
        ),
        CourseModel(
          id: 'nlp-3',
          title: 'Sentiment Analysis',
          description:
              'Build models to classify opinions and emotions in text.',
          duration: '3h 15m',
          level: 'Intermediate',
          lessons: 12,
          rating: 4.8,
        ),
        CourseModel(
          id: 'nlp-4',
          title: 'Named Entity Recognition',
          description:
              'Extract people, places, and organizations from unstructured text.',
          duration: '2h 50m',
          level: 'Advanced',
          lessons: 10,
          rating: 4.5,
        ),
      ],
    ),
    PathwayModel(
      id: 'computer-vision',
      title: 'Computer Vision',
      description:
          'Teach machines to see — from image classification to real-time detection.',
      icon: 'computer-vision',
      colorIndex: 3,
      totalHours: 26,
      courses: [
        CourseModel(
          id: 'cv-1',
          title: 'Image Processing Fundamentals',
          description:
              'Filters, edge detection, and core image manipulation techniques.',
          duration: '3h 00m',
          level: 'Beginner',
          lessons: 12,
          rating: 4.7,
        ),
        CourseModel(
          id: 'cv-2',
          title: 'Object Detection with YOLO',
          description:
              'Real-time object detection using state-of-the-art YOLO models.',
          duration: '4h 45m',
          level: 'Intermediate',
          lessons: 16,
          rating: 4.9,
        ),
        CourseModel(
          id: 'cv-3',
          title: 'Semantic Segmentation',
          description:
              'Pixel-level classification for medical imaging and autonomous driving.',
          duration: '3h 30m',
          level: 'Advanced',
          lessons: 14,
          rating: 4.6,
        ),
      ],
    ),
    PathwayModel(
      id: 'generative-ai',
      title: 'Generative AI',
      description:
          'Create with AI — LLMs, diffusion models, and prompt engineering.',
      icon: 'generative-ai',
      colorIndex: 4,
      totalHours: 30,
      courses: [
        CourseModel(
          id: 'gen-1',
          title: 'Prompt Engineering Mastery',
          description:
              'Craft effective prompts for ChatGPT, Claude, and other LLMs.',
          duration: '2h 30m',
          level: 'Beginner',
          lessons: 10,
          rating: 4.9,
        ),
        CourseModel(
          id: 'gen-2',
          title: 'Building with LLM APIs',
          description:
              'Integrate OpenAI, Anthropic, and open-source models into apps.',
          duration: '4h 00m',
          level: 'Intermediate',
          lessons: 15,
          rating: 4.8,
        ),
        CourseModel(
          id: 'gen-3',
          title: 'RAG: Retrieval Augmented Generation',
          description:
              'Build AI apps that search your data and generate accurate answers.',
          duration: '5h 20m',
          level: 'Intermediate',
          lessons: 18,
          rating: 4.9,
        ),
        CourseModel(
          id: 'gen-4',
          title: 'Stable Diffusion & Image Generation',
          description:
              'Generate stunning images with diffusion models and fine-tuning.',
          duration: '4h 10m',
          level: 'Advanced',
          lessons: 14,
          rating: 4.7,
        ),
      ],
    ),
    PathwayModel(
      id: 'mlops',
      title: 'MLOps & Deployment',
      description:
          'Deploy, monitor, and scale ML models in production environments.',
      icon: 'mlops',
      colorIndex: 5,
      totalHours: 22,
      courses: [
        CourseModel(
          id: 'ops-1',
          title: 'ML Pipeline Design',
          description:
              'Design reproducible pipelines from data ingestion to model serving.',
          duration: '3h 15m',
          level: 'Intermediate',
          lessons: 12,
          rating: 4.6,
        ),
        CourseModel(
          id: 'ops-2',
          title: 'Model Serving with FastAPI',
          description:
              'Expose ML models as REST APIs with FastAPI and Docker.',
          duration: '3h 45m',
          level: 'Intermediate',
          lessons: 14,
          rating: 4.8,
        ),
        CourseModel(
          id: 'ops-3',
          title: 'Monitoring & Drift Detection',
          description:
              'Track model performance and detect data drift in production.',
          duration: '2h 50m',
          level: 'Advanced',
          lessons: 10,
          rating: 4.5,
        ),
      ],
    ),
  ];

  static PathwayModel? getPathwayById(String id) {
    try {
      return pathways.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
