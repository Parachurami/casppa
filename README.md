# Casppa — Module 14: Assessments

Casppa is a school management platform. This submission implements **Module 14 — Assessments**, covering **Assignments** and **CBT (Computer-Based Tests)**: teachers set work, students submit and resubmit, teachers mark (including inline annotations on images/PDFs), grade, and return work; students and parents view feedback in real time. Admins have read-only, school-wide oversight.

## Demo credentials

**Admin**
- Email: `panumeri0user@gmail.com`
- Password: `password`

Teacher, student, and parent accounts can be created from the in-app **Sign up** flow (role selector on the sign-up screen). Students pick their class at sign-up; parents pick a class and then select one or more children in it (repeatable across classes) before submitting.

## Stack

- **Frontend:** Flutter (Dart), null-safe, state management via **Riverpod**.
- **Backend:** Supabase — Auth (email/password, role-based), Postgres (assignments, submissions, annotations, grades, notifications), Storage (submission files), and Realtime (live grading notifications via `postgres_changes`).
- **Local storage:** Hive — the app is **offline-first**; each feature's repository reads/writes through a local (Hive) datasource in addition to the remote (Supabase) one, reconciled via `NetworkInfo`, so cached data stays visible while offline and refreshes automatically once back online.
- **Error handling:** `fpdart`'s `Either<Failure, T>` — repositories return `ResultFuture<T>`, never throw across layer boundaries.
- **DI:** `get_it`, wired per-feature in `lib/app/core/di/injection_container.dart`.

## Architecture

Clean Architecture, organized by layer first, then feature, under `lib/app/`:

- `core/` — cross-cutting concerns: errors (Failures/Exceptions), usecases, services (`NetworkInfo`, `HiveService`), theme, utils (typedefs, constants, the `AppLogger` diagnostic logger), DI container.
- `domain/<feature>/` — entities, abstract repositories, usecases, params. No Supabase/Hive imports.
- `data/<feature>/` — remote (Supabase) and local (Hive) datasources, models, and repository implementations that combine both behind the domain interface.
- `presentation/<feature>/` — Riverpod providers, pages, widgets.

Features: `auth`, `assignments` (assignments + CBT + submissions + annotations), `admin`, `parent`, `notifications`, `onboarding`.

## User roles

- **Teacher** — creates assignments/CBTs, marks submissions with inline pen/highlighter/comment-pin annotations (images) or sidebar comments (PDFs), assigns a score + status (Excellent / Satisfactory / Needs Revision) + feedback, then Saves & Grades or Returns to the student. Editing is locked once a test/assignment has submissions.
- **Student** — submits text/image/PDF work or answers CBT questions (MCQ / True-False auto-graded instantly; short-answer held as pending until marked). Sees live feedback and can always resubmit returned work (the resubmit form pre-populates the previous answer; resubmission replaces the prior submission for re-marking).
- **Parent** — signs up by linking one or more children, sees a per-child summary (including an average score normalized to a 0–100% scale) on a single dashboard with no bottom navigation, and can drill into a full report for just that child. Receives real-time notifications the moment any linked child is graded.
- **Admin** — floating bottom-nav shell (Home / Assessments / Students / Teachers). Home shows a school-wide overview (subject/class/student/teacher counts) plus Subjects/Classes CRUD. Assessments, Students, and Teachers tabs are read-only oversight across every teacher's work.

## Key behaviors

- Image annotation pins are stored as **percentage coordinates**, so they restore at the exact spot regardless of screen size; pen strokes, highlights, and PDF sidebar comments all persist and restore across sessions.
- Returning a submission notifies **both** the student and their parent(s) with grade + feedback, in-app and via a live toast while the app is open (Supabase Realtime).
- Overdue CBTs show a badge and cannot be submitted.
- All list/detail screens handle empty, loading (shimmer), and error (with Retry) states, and support pull-to-refresh.

## Running the project

1. Install Flutter (this project targets Dart SDK `^3.12.2`) and run:
   ```
   flutter pub get
   ```
2. Supabase project config lives in `lib/app/core/utils/app_constants.dart` (URL + publishable/anon key already set for the submission project).
3. Apply the SQL migrations in `supabase/sql/` **in numeric order** (0001 → 0012) via the Supabase SQL editor — they're idempotent and safe to re-run.
4. Run the app:
   ```
   flutter run
   ```

## Tests

```
flutter test
```

## Out of scope / notes

- Push notifications (FCM) are not wired up; in-app real-time notifications (Supabase Realtime) cover the "notify on grade" requirement while the app is open.
- Admin analytics beyond the overview counts, and a couple of lower-priority offline-cache paths (e.g. admin/parent detail views), are deliberately remote-only rather than cached locally, since they're oversight/reporting screens rather than the core offline-first submission flow.
