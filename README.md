# 🟧 Scientific Calculator App with AI — README.md

## 🔢 AI-Powered Scientific Calculator (Flutter + ChatGPT API)

A cross-platform (iOS/Android) calculator with advanced scientific functions, conversions, and natural language AI.

### ✨ Features

* Standard & scientific calculations
* Constants storage
* Unit & currency conversions
* Voice input (coming soon)
* AI chatbot for natural queries like:

  > "solve 3x + 5 = 20"
  > "convert 150 USD to SGD"
* Works on iOS & Android

### 🛠 Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** REST API (Python or Dart)
* **AI:** ChatGPT API
* **State Management:** Provider/GetX (your choice)

### 📁 Project Structure

```
/lib
  ├── main.dart
  ├── screens/
  ├── widgets/
  ├── services/
      └── ai_service.dart
```

### ▶️ Running the App

```bash
flutter pub get
flutter run
```

### 🔌 API Integration (ChatGPT)

Example (Dart):

```dart
final response = await http.post(
  Uri.parse("https://api.openai.com/v1/chat/completions"),
  headers: {"Authorization": "Bearer YOUR_KEY"},
  body: jsonEncode({...})
);
```

### 📌 Future Improvements

* Store calculation history
* Offline mode
* More AI-based functions
* Deploy backend to Azure/AWS
