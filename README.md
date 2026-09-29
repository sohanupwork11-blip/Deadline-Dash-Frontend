# Deadline Dash Frontend

A Flutter app for Deadline Dash project planning, deadline tracking, and task progress. It connects to the Django REST API with JWT authentication.

## Run

Install Flutter, then from this directory run:

```sh
flutter pub get
flutter run -d chrome --web-port=3000
```

The default API URL is `http://localhost:8000/api`. For an Android emulator, pass `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api`. For a deployed API, supply its HTTPS URL with the same `API_BASE_URL` define. Android cleartext traffic is enabled for local development; use HTTPS in production.

The backend must allow the web app origin in `CORS_ALLOWED_ORIGINS`. Configure the backend `DJANGO_ALLOWED_HOSTS` and CORS environment variables for deployed environments.

## Features

- Sign in and create an account using the backend JWT endpoints.
- View owned projects, task counts, completion progress, and due dates.
- Create projects and prioritized tasks.
- Review subscription plan information.
- Responsive layouts for mobile and desktop widths.