# Money Manager App 💰

A modern, feature-rich money management application built with Flutter and Firebase. Track your income and expenses across multiple books, visualize your spending patterns, and manage your finances effectively.

## Features ✨

### Core Functionality
- **Multiple Books**: Create separate books for different purposes (e.g., Daily, Business, Personal)
- **Transaction Tracking**: Record income and expenses with detailed information
- **Categories**: Pre-defined categories for quick transaction classification
  - **Expense**: Food, Transport, Shopping, Bills, Entertainment, Health, Education, Other
  - **Income**: Salary, Freelance, Investment, Gift
- **Real-time Statistics**: View income, expense, and balance for each book
- **Date Tracking**: Record and view transactions chronologically
- **Search & Filter**: Find transactions easily

### User Management
- **Authentication**: Secure email/password login and signup
- **User Profiles**: Personal data storage
- **Multi-device Sync**: Cloud-based data storage with Firebase

### UI/UX
- **Material Design 3**: Modern, clean interface
- **Responsive Design**: Works on different screen sizes
- **Custom Icons & Colors**: Personalize your books
- **Empty States**: Helpful guidance when no data exists
- **Loading States**: Smooth user experience with progress indicators
- **Error Handling**: User-friendly error messages

## Tech Stack 🛠️

- **Framework**: Flutter 3.0+
- **Language**: Dart 3.0+
- **State Management**: Riverpod (3.2.1)
- **Backend**: Firebase
  - Firebase Auth (6.1.4)
  - Cloud Firestore (6.1.2)
- **Local Storage**: 
  - sqflite (2.4.2)
  - shared_preferences (2.5.4)
  - path_provider (2.1.5)
- **Formatting**: intl (0.18.1)

## Architecture 🏗️

```
lib/
├── models/           # Data models
│   ├── book.dart
│   ├── transaction.dart
│   ├── category.dart
│   └── user_model.dart
├── services/         # Business logic
│   ├── auth_service.dart
│   └── database_service.dart
├── providers/        # Riverpod state management
│   ├── auth_provider.dart
│   ├── book_provider.dart
│   └── transaction_provider.dart
├── screens/          # UI screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── books_screen.dart
│   ├── create_book_screen.dart
│   ├── book_detail_screen.dart
│   └── add_transaction_screen.dart
└── main.dart         # App entry point
```

## Prerequisites 📋

1. **Flutter SDK**: Version 3.0.0 or higher
2. **Firebase Project**: Create a project at [Firebase Console](https://console.firebase.google.com/)
3. **FlutterFire CLI**: For Firebase configuration
4. **IDE**: VS Code or Android Studio with Flutter extensions

## Setup Instructions 🚀

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Firebase

#### Install FlutterFire CLI (if not already installed)
```bash
dart pub global activate flutterfire_cli
```

#### Login to Firebase
```bash
firebase login
```

#### Configure FlutterFire
```bash
flutterfire configure
```

This will:
- Create or select a Firebase project
- Generate `lib/firebase_options.dart`
- Configure Firebase for all platforms

#### Set up Firebase Authentication
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** > **Sign-in method**
4. Enable **Email/Password** provider

#### Set up Cloud Firestore
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in production mode**
4. Select a region
5. Update Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /books/{bookId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null && 
                              get(/databases/$(database)/documents/books/$(bookId)).data.userId == request.auth.uid;
      }
    }
  }
}
```

### 3. Run the App
```bash
flutter run
```

## Usage Guide 👤

### First Time Setup
1. **Sign Up**: Create an account with email and password
2. **Create a Book**: Click the + button to create your first book
3. **Add Transactions**: Open a book and add income/expenses

### Adding Transactions
1. Select transaction type (Income/Expense)
2. Choose a category
3. Enter amount
4. Add description (optional)
5. Select date
6. Save

### Managing Books
- **Create**: Customize name, icon, and color
- **Edit**: Update book details
- **Delete**: Remove book and all transactions
- **View**: See statistics and transaction history

## Color Scheme 🎨

- **Primary**: Purple (`#5F27CD`)
- **Secondary**: Teal (`#00D2D3`)
- **Expense**: Red (`#E74C3C`)
- **Income**: Green (`#00B894`)

## Troubleshooting 🔧

### Firebase Initialization Error
**Solution**: Run `flutterfire configure` and restart the app

### Package Link Warnings (Windows)
**Solution**: Enable Developer Mode in Windows Settings

### Login/Signup Fails
- Check Firebase Authentication is enabled
- Verify internet connection
- Check Firebase Console logs

## Building for Release 📦

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Future Enhancements 🚧

- [ ] Transaction editing
- [ ] Date range filtering
- [ ] Charts and visualizations
- [ ] Export to CSV/PDF
- [ ] Budget tracking
- [ ] Dark mode
- [ ] Offline mode with sync

## License 📄

This project is licensed under the MIT License.

---

Made with ❤️ using Flutter

