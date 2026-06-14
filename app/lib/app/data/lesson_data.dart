import '../models/lesson_model.dart';

class LessonData {
  LessonData._();

  static List<LessonModel> getLessons(String courseId) {
    switch (courseId) {
      case 'ml-1':
        return [
          const LessonModel(
            title: 'Welcome to Machine Learning',
            duration: '8 min',
            body: 'Machine learning is a subset of artificial intelligence that focuses on building systems that learn from and make decisions based on data. Instead of writing explicit rules to solve a problem, we feed data into an algorithm which fits a mathematical model to represent the patterns. This process is called training. Once trained, the model can make predictions or decisions on unseen data.',
            codeSnippet: '''# Welcome to Machine Learning
# Let's check our setup and load a simple dataset
import numpy as np

# Create simple feature (X) and label (y) vectors
X = np.array([[1, 2], [2, 3], [3, 4], [4, 5]])
y = np.array([0, 0, 1, 1])

print("Features X:\\n", X)
print("Labels y:\\n", y)''',
          ),
          const LessonModel(
            title: 'Supervised vs Unsupervised Learning',
            duration: '10 min',
            body: 'Supervised learning is where the model is trained on labeled data—meaning each training example is paired with its correct output label (like predicting house prices or spam detection). Unsupervised learning, on the other hand, deals with unlabeled data. The algorithm tries to learn the underlying structure of the data without guidance (like clustering customers by purchasing habits).',
            codeSnippet: '''# Supervised classification with scikit-learn
from sklearn.linear_model import LogisticRegression
import numpy as np

X = np.array([[1], [2], [8], [9]])
y = np.array([0, 0, 1, 1]) # 0 = small, 1 = large

model = LogisticRegression()
model.fit(X, y)

test_data = np.array([[1.5], [7.5]])
predictions = model.predict(test_data)
print("Predictions for [1.5, 7.5]:", predictions)''',
          ),
          const LessonModel(
            title: 'The Machine Learning Lifecycle',
            duration: '12 min',
            body: 'An ML project involves multiple phases: defining the problem, gathering and cleaning data, selecting features, training the model, evaluating its performance, and deploying it. Data preprocessing is often the most time-consuming phase, as models are highly sensitive to noise, missing values, and scale differences.',
            codeSnippet: '''# Preprocessing: Scale features to range [0, 1]
from sklearn.preprocessing import MinMaxScaler
import numpy as np

data = np.array([[-1.0, 2.0], [-0.5, 6.0], [0.0, 10.0], [1.0, 18.0]])
scaler = MinMaxScaler()
scaled_data = scaler.fit_transform(data)

print("Scaled Data:\\n", scaled_data)''',
          ),
        ];

      case 'ml-2':
        return [
          const LessonModel(
            title: 'Understanding Linear Regression',
            duration: '10 min',
            body: 'Linear regression is the foundational algorithm for predicting continuous values. It assumes a linear relationship between input variables (X) and a single output variable (y). The model finds a line of best fit by minimizing the sum of squared differences (residual sum of squares) between the predicted and actual values.',
            codeSnippet: '''# Simple Linear Regression
from sklearn.linear_model import LinearRegression
import numpy as np

# X: square feet, y: house price (k\$)
X = np.array([[1000], [1500], [2000], [2500]])
y = np.array([200, 280, 390, 470])

reg = LinearRegression()
reg.fit(X, y)

print("Slope (Coefficient):", reg.coef_[0])
print("Intercept:", reg.intercept_)
print("Predict 1800 sq ft:", reg.predict([[1800]])[0])''',
          ),
          const LessonModel(
            title: 'Logistic Regression for Classification',
            duration: '12 min',
            body: 'Despite its name, Logistic Regression is used for binary classification, not regression. It uses the sigmoid function to map predicted continuous values to probabilities between 0 and 1. If the probability is above a threshold (typically 0.5), it predicts class 1; otherwise, class 0.',
            codeSnippet: '''# Logistic Regression Example
from sklearn.linear_model import LogisticRegression
import numpy as np

X = np.array([[0.5], [1.5], [3.0], [4.5]])
y = np.array([0, 0, 1, 1])

clf = LogisticRegression()
clf.fit(X, y)

probs = clf.predict_proba([[2.0]])
print("Probability of class 0 and 1:", probs)''',
          ),
        ];

      case 'dl-1':
        return [
          const LessonModel(
            title: 'Introduction to Artificial Neural Networks',
            duration: '12 min',
            body: 'Neural networks are inspired by the human brain. They consist of layers of interconnected nodes (neurons): an input layer, one or more hidden layers, and an output layer. Each connection has a weight and bias. Neurons process inputs by multiplying them by weights, summing them, adding a bias, and applying an activation function.',
            codeSnippet: '''# Simple neuron computation in NumPy
import numpy as np

inputs = np.array([2.0, 3.0])
weights = np.array([0.5, -0.8])
bias = 0.1

# Weighted sum + bias
z = np.dot(inputs, weights) + bias

# Sigmoid activation function
def sigmoid(x):
    return 1 / (1 + np.exp(-x))

output = sigmoid(z)
print("Neuron Output:", output)''',
          ),
          const LessonModel(
            title: 'Backpropagation and Gradient Descent',
            duration: '15 min',
            body: 'To train a neural network, we calculate a loss representing the difference between predicted and actual values. Backpropagation calculates the gradient of the loss function with respect to the weights and biases using the chain rule of calculus. Gradient descent then updates the weights in the opposite direction of the gradient to minimize the loss.',
            codeSnippet: '''# Forward and backward pass mockup
import numpy as np

x = 1.0  # input
w = 0.5  # weight
y_true = 1.0  # true label

# Forward pass
y_pred = x * w
loss = (y_pred - y_true) ** 2

# Backpropagation (derivative of loss w.r.t w)
# dLoss/dw = dLoss/dy_pred * dy_pred/dw
# = 2 * (y_pred - y_true) * x
dw = 2 * (y_pred - y_true) * x

# Update weight with learning rate 0.1
learning_rate = 0.1
w = w - learning_rate * dw
print("Updated weight:", w)''',
          ),
        ];

      case 'dl-4':
        return [
          const LessonModel(
            title: 'The Transformer Revolution',
            duration: '15 min',
            body: 'Introduced in 2017 by Google researchers, the Transformer architecture replaced sequence-based models like LSTMs. Transformers process entire sequences of data in parallel, allowing for highly efficient training. Their key mechanism is Self-Attention, which allows the model to compute representations of input sequences by looking at other positions in the sequence simultaneously.',
            codeSnippet: '''# Simplified self-attention computation in PyTorch
import torch
import torch.nn.functional as F

# 3 words, embedding dimension 4
embeddings = torch.randn(3, 4)

# Define Query, Key, Value weights
W_q = torch.randn(4, 4)
W_k = torch.randn(4, 4)
W_v = torch.randn(4, 4)

Q = embeddings @ W_q
K = embeddings @ W_k
V = embeddings @ W_v

# Attention scores
scores = Q @ K.T
weights = F.softmax(scores / (4 ** 0.5), dim=-1)
output = weights @ V

print("Attention Output:\\n", output)''',
          ),
        ];

      case 'gen-1':
        return [
          const LessonModel(
            title: 'Introduction to Prompt Engineering',
            duration: '10 min',
            body: 'Prompt engineering is the practice of structured input design for Large Language Models (LLMs) to get desired outputs. Good prompts define a role, provide clear instructions, set the context, and specify output constraints. Adding few-shot examples (examples of inputs and desired outputs) drastically improves performance.',
            codeSnippet: '''# System and User Prompts example
system_prompt = """You are a polite customer support assistant. 
Answer questions briefly and concisely. Do not use technical jargon."""

user_prompt = "Why is my internet connection slow?"

# Format message for LLM APIs
messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": user_prompt}
]

print("Structured LLM prompt payload:")
print(messages)''',
          ),
        ];

      case 'ops-2':
        return [
          const LessonModel(
            title: 'Building REST APIs for ML Serving',
            duration: '12 min',
            body: 'FastAPI is a modern, high-performance web framework for building APIs with Python. It is ideal for ML model serving due to its speed, automatic documentation, and typed request validation using Pydantic. We load our serialized models (like .pkl files) at startup and serve predictions via HTTP POST endpoints.',
            codeSnippet: '''# FastAPI serving script
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class Features(BaseModel):
    area: float
    rooms: int

@app.post("/predict")
def predict_price(data: Features):
    # Mock prediction logic: price = area * 1.5 + rooms * 10
    prediction = data.area * 1.5 + data.rooms * 10.0
    return {"predicted_price_k": prediction}

# Run with: uvicorn app:app --reload''',
          ),
        ];

      default:
        return [
          const LessonModel(
            title: 'Introduction to the Subject',
            duration: '10 min',
            body: 'This course covers advanced methods to design, scale, and evaluate robust engineering pipelines. We will begin with the fundamentals, reviewing core definitions, mathematical properties, and architectural design patterns. In subsequent lessons, we will explore implementation strategies, troubleshooting techniques, and performance optimizations for modern workloads.',
            codeSnippet: '''# Core function implementation
def execute_pipeline(data_stream):
    print("Initializing pipeline processing...")
    processed = [x * 2 for x in data_stream if x > 0]
    print("Processing complete. Elements:", len(processed))
    return processed

result = execute_pipeline([5, -1, 12, 0, 8])
print("Resulting stream:", result)''',
          ),
          const LessonModel(
            title: 'Deep Dive and Practical Implementation',
            duration: '12 min',
            body: 'Moving from concept to code requires setting up clean abstractions, handling edge cases, and managing configurations. Today we will code the core engine and test it under mock workloads. Pay close attention to scale requirements and ensure memory efficiency by using generators where appropriate.',
            codeSnippet: '''# Generator approach for memory efficiency
def stream_chunks(data_list, chunk_size=2):
    for i in range(0, len(data_list), chunk_size):
        yield data_list[i:i + chunk_size]

for chunk in stream_chunks([1, 2, 3, 4, 5, 6, 7]):
    print("Processing chunk:", chunk)''',
          ),
          const LessonModel(
            title: 'Testing and Optimization Techniques',
            duration: '12 min',
            body: 'To prepare our system for production, we must write tests that validate core functionality and profile resource usage. By instrumenting our execution, we can identify bottlenecks and optimize critical code paths. We will look at both CPU and memory profiling tools, and how to set up automated verification runs.',
            codeSnippet: '''# Mock testing verification
def test_pipeline():
    test_input = [1, 2, 3]
    expected = [2, 4, 6]
    
    # Simple assertion validation
    from execute import execute_pipeline
    assert execute_pipeline(test_input) == expected
    print("All unit tests passed successfully!")

# test_pipeline()''',
          ),
        ];
    }
  }
}
