# HitUp Chat App

HitUp is a real-time chat application built using Flutter and Firebase Realtime Database. It provides a seamless and responsive chatting experience, enabling users to communicate efficiently with their contacts.

## Features

- **User Authentication**: Sign up and log in using email and password.
- **Real-time Messaging**: Send and receive messages instantly.
- **Message Storage**: Store chat data in Firebase Realtime Database.
- **Group Chats**: Create and manage group conversations.
- **Profile Management**: Update user profile information like name and profile picture.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Realtime Database
- **Authentication**: Firebase Authentication

## Prerequisites

1. Install Flutter SDK ([Flutter Installation Guide](https://flutter.dev/docs/get-started/install)).
2. Set up a Firebase project ([Firebase Setup Guide](https://firebase.google.com/docs)).

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hitup-chat-app.git
   cd hitup-chat-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Add the `google-services.json` file to the `android/app` directory.
   - Add the `GoogleService-Info.plist` file to the `ios/Runner` directory.
   - Configure Firebase project settings in `firebase_options.dart` (generated using `flutterfire configure`).

4. Run the application:
   ```bash
   flutter run
   ```

## Key Features Explained

### Real-time Messaging
Messages are stored and retrieved from Firebase Realtime Database. Each chat is represented by a node containing user-specific data and message history.

### User Authentication
Firebase Authentication is used to manage user sign-up and log-in securely. Authenticated users are registered in the database under a `users` node.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit changes:
   ```bash
   git commit -m "Added new feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature-name
   ```
5. Create a pull request.

---


