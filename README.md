# Helpr

**Helpr** is a mobile-first service marketplace that connects **Requesters** with local gig workers — plumbers, electricians, repair technicians, and more — in Pakistan. Requesters can post service requests, receive bids from nearby workers, and hire the best fit. Workers can browse open requests, place bids, chat with clients, and build their reputation through ratings and reviews.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Environment Variables](#environment-variables)
- [API Overview](#api-overview)
- [Screens](#screens)

---

## Features

**For Requesters**
- Sign up and complete a profile
- Post service requests (type, description, date/time, location)
- Browse incoming bids and accept or reject them
- Track active jobs in real time
- View job history and leave ratings/reviews

**For Workers**
- Sign up and complete a profile with skills and availability
- Browse open service requests
- Place bids on relevant jobs
- Chat with requesters before and during a job
- View job history, earnings, and received ratings

**Shared**
- Phone number-based authentication with bcrypt password hashing
- In-app chat between workers and requesters
- Public worker profiles with average ratings

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Backend API | Node.js + Express.js |
| Database | Microsoft SQL Server |
| Authentication | bcrypt (password hashing) |
| File Uploads | Multer |
| HTTP Client (Flutter) | `http` package |
| Image Handling | `image_picker` package |
| Fonts | Google Fonts |

---

## Project Structure

```
helpr-mobile-app-main/
├── backend/
│   ├── app.js                  # Express app setup and route mounting
│   ├── config/
│   │   └── db.js               # SQL Server connection pool
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── chatController.js
│   │   ├── profileController.js
│   │   ├── profileCompletionController.js
│   │   ├── requesterController.js
│   │   └── workerController.js
│   └── routes/
│       ├── authRoutes.js
│       ├── chatRoutes.js
│       ├── profileRoutes.js
│       ├── profileCompletionRoutes.js
│       ├── requesterRoutes.js
│       └── workerRoutes.js
└── frontend/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── services/
        │   └── api_service.dart
        ├── screens/
        │   ├── splash_screen.dart
        │   ├── login_screen.dart
        │   ├── signup_screen.dart
        │   ├── worker_dashboard.dart
        │   ├── requester_dashboard.dart
        │   ├── post_request_screen.dart
        │   ├── browse_requests_screen.dart
        │   ├── browse_bids.dart
        │   ├── received_bids_screen.dart
        │   ├── chat_screen.dart
        │   ├── chat_list_screen.dart
        │   ├── job_detail.dart
        │   ├── job_history.dart
        │   ├── rating_review_screen.dart
        │   └── ...
        └── widgets/
            └── appbar.dart
```

---

## Prerequisites

- **Flutter SDK** `^3.11.4` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Node.js** v18+ and npm
- **Microsoft SQL Server** (local instance or Azure SQL)
- Linux users will also need:
  ```bash
  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev lld
  ```

---

## Getting Started

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file in the `backend/` directory (see [Environment Variables](#environment-variables)).

4. Start the server:
   ```bash
   node index.js
   ```
   The API will be available at `http://localhost:<PORT>`.

---

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Update the base API URL in `lib/services/api_service.dart` to point to your running backend.

4. Run the app:
   ```bash
   flutter run
   ```

---

## Environment Variables

Create a `.env` file inside the `backend/` directory with the following keys:

```env
DB_USER=your_db_username
DB_PASSWORD=your_db_password
DB_SERVER=your_server_address
DB_DATABASE=your_database_name
DB_INSTANCE=your_sql_instance_name   # optional, for named instances
PORT=3000
```

---

## API Overview

All routes are prefixed with `/api`.

| Prefix | Description |
|---|---|
| `/api/auth` | Sign up and log in |
| `/api/profile` | Fetch and update user profiles |
| `/api/profile-completion` | Complete worker or requester profile setup |
| `/api/requester` | Post requests, view bids, manage jobs |
| `/api/worker` | Browse requests, place bids, manage jobs |
| `/api/chat` | Send and retrieve messages |

---

## Screens

| Screen | Role |
|---|---|
| Splash / Login / Signup | All users |
| Requester Dashboard | Requester |
| Post Request | Requester |
| Received Bids | Requester |
| Active Jobs / Job Tracking | Requester |
| Job History | Requester |
| Requester Profile & Completion | Requester |
| Worker Dashboard | Worker |
| Browse Requests | Worker |
| Browse Bids | Worker |
| Job Detail / Job History | Worker |
| Worker Profile & Completion | Worker |
| Worker Public Profile | All users |
| Chat / Chat List | All users |
| Rating & Review | All users |
