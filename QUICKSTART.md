# Quick Start Guide

## Money Manager App - Getting Started

### Prerequisites
Before you begin, make sure you have:
- Flutter SDK installed (3.0 or higher)
- A Firebase account
- An IDE (VS Code or Android Studio)

### Step 1: Verify Flutter Installation
```bash
flutter --version
flutter doctor
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Step 4: Login to Firebase
```bash
firebase login
```

### Step 5: Configure Firebase for Your Project
```bash
flutterfire configure
```

Follow the prompts to:
1. Select/create a Firebase project
2. Select platforms (Android, iOS, Web)
3. This will generate `lib/firebase_options.dart`

### Step 6: Enable Firebase Services

#### Enable Authentication:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Click **Email/Password** and enable it
5. Click **Save**

#### Enable Firestore Database:
1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in production mode**
4. Select your preferred region
5. Click **Enable**

#### Set Firestore Security Rules:
1. In Firestore, click **Rules** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Books collection
    match /books/{bookId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      
      // Transactions subcollection
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null && 
                              get(/databases/$(database)/documents/books/$(bookId)).data.userId == request.auth.uid;
      }
    }
  }
}
```

3. Click **Publish**

### Step 7: Update main.dart Firebase Initialization
Make sure `lib/main.dart` imports Firebase options correctly:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Step 8: Run the App

#### For Android:
```bash
flutter run
```

#### For iOS (Mac only):
```bash
flutter run
```

#### For Web:
```bash
flutter run -d chrome
```

### Step 9: Create Your First Account
1. Click **Don't have an account? Sign up**
2. Enter your name, email, and password
3. Click **Sign Up**

### Step 10: Start Using the App
1. Click the **+** button to create your first book
2. Customize the name, icon, and color
3. Save the book
4. Tap the book to open it
5. Click **+** to add your first transaction
6. Choose income or expense
7. Fill in the details
8. Save!

## Common Issues & Solutions

### Issue: "Firebase initialization failed"
**Solution**: Make sure you ran `flutterfire configure` and that `firebase_options.dart` exists in `lib/`

### Issue: "Email/Password sign in is disabled"
**Solution**: Go to Firebase Console → Authentication → Sign-in method → Enable Email/Password

### Issue: "Permission denied" when creating books/transactions
**Solution**: Update Firestore security rules as shown in Step 6

### Issue: Package installation warnings on Windows
**Solution**: Optional - Enable Developer Mode in Windows Settings → Update & Security → For developers

## App Features

### Books
- Create multiple books for different purposes
- Customize with 16 icons and 10 colors
- Edit or delete books
- Each book tracks its own transactions

### Transactions
- Record income and expenses
- Choose from 12 predefined categories
- Add descriptions
- Set custom dates
- View all transactions in chronological order

### Statistics
- View total income per book
- Track total expenses
- See current balance
- Real-time updates

### Categories
**Expenses:**
- 🍔 Food
- 🚗 Transport
- 🛍️ Shopping
- 💰 Bills
- 🎬 Entertainment
- 🏥 Health
- 📚 Education
- 📦 Other

**Income:**
- 💵 Salary
- 💼 Freelance
- 📈 Investment
- 🎁 Gift

## Tips for Best Use

1. **Separate Books**: Create different books for personal, business, daily, monthly, etc.
2. **Regular Updates**: Add transactions as they happen for accurate tracking
3. **Use Descriptions**: Add notes to remember what each transaction was for
4. **Check Statistics**: Review your income and expenses regularly
5. **Backup**: Your data is automatically backed up to Firebase Cloud

## Need Help?

- Check `README.md` for detailed documentation
- Review `SETUP.md` for Firebase setup details
- Open an issue on GitHub
- Contact support

---

Happy money managing! 💰
