# OmegleCloneAPP-Flutter

This repository contains a Flutter-based implementation of an Omegle clone, allowing users to randomly connect with others for video and text chats. The application leverages WebRTC for peer-to-peer video communication, along with Socket.IO for real-time messaging and room management.

## Features
- Random video chat with other users.
- Toggle video and audio streams.
- Search for new partners with a single click.

## Technical Stack
- **Flutter**: Frontend framework.
- **PeerDart**: Wrapper for WebRTC to handle peer connections.
- **Flutter WebRTC**: WebRTC implementation for Flutter.
- **Socket.IO**: Real-time communication and event handling.

## Getting Started

1. **Clone the repository**:
    ```bash
    git clone https://github.com/prajwalpkp2106/OmegleCloneAPP-Flutter.git
    cd OmegleCloneAPP-Flutter
    ```

2. **Install dependencies**:
    ```bash
    flutter pub get
    ```

3. **Run the application on emulators or mobile devices**:
    ```bash
    flutter run
    ```

## Live Server
The application connects to a live backend server hosted at [https://omegleclone.onrender.com](https://omegleclone.onrender.com). This server handles the WebSocket connections and room management required for the random chat functionality.

## App Insights

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

### Challenge: Add Messaging Feature
Feeling up for a challenge? Enhance the app by adding a messaging feature alongside video chat! You can use the existing WebSocket setup for this purpose. Fork the repository and show us your skills by implementing a seamless text messaging feature integrated with the current video chat functionality. Happy coding!
