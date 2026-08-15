# Casppa — M14: Assessments Module

## Overview
Casppa is a school management platform. This project implements **Module 14 — Assessments**, covering **Assignments** and **CBT (Computer-Based Tests)**. Teachers set work, students submit and resubmit, teachers mark (including inline annotations on images/PDFs), grade, and return work; students and parents view feedback. Admins have school-wide oversight.

## Stack
- **Frontend:** Flutter (Dart), null-safe. State management: **Riverpod**.
- **Backend:** Supabase
  - **Auth** — email/password, role-based access (teacher / student / parent / admin).
  - **Postgres (via Supabase)** — primary data store (assignments, submissions, annotations, grades).
  - **Supabase Storage** — student submission files (images, PDFs).
  - **Push notifications** to student + parent on return (provider TBD — e.g. FCM or Supabase-triggered).
- **Local storage:** Hive — this is an **offline-first** app; each feature's repository reads/writes through a local (Hive) datasource in addition to the remote (Supabase) one, reconciled via `NetworkInfo`.
- **Either / error handling:** `fpdart`'s `Either<Failure, T>` — repositories return `ResultFuture<T>` (see `core/utils/typedefs.dart`), never throw across layer boundaries.
- **DI:** `get_it`, wired per-feature in `core/di/injection_container.dart`.
- UI must match the provided Figma design (link supplied separately).

## Architecture — Clean Architecture (no top-level `features/` folder)
Under `lib/app/`, split first by layer, then by feature — **not** by feature-then-layer:

- `core/` — cross-cutting: `errors/` (Failures, Exceptions), `usecases/` (base `UseCase`), `services/` (`NetworkInfo`, `HiveService`), `theme/`, `utils/` (typedefs, constants, Hive type-id registry), `di/` (GetIt container).
- `domain/<feature>/` — `entities/`, `repositories/` (abstract interfaces), `usecases/`, `params/` (e.g. `AuthLoginParams` — shapes usecase input). No Firebase/Supabase/Hive imports allowed here.
- `data/<feature>/` — `datasources/remote/` (Supabase), `datasources/local/` (Hive), `models/` (extend the domain entity, add `fromJson`/`toJson`/Hive adapters), `repositories/` (implements the domain repository interface, combining remote + local + `NetworkInfo`).
- `presentation/<feature>/` — `provider/` (Riverpod providers/notifiers), `pages/`, `widgets/`.

The `auth` feature (`domain/auth`, `data/auth`, `presentation/auth`) is the reference implementation of this pattern — follow its structure when adding new features (e.g. `assignments`, `cbt`, `submissions`, `notifications`).

## User Roles
- **Teacher** — creates assignments/CBT, marks with inline comments, grades, returns work.
- **Student** — submits, resubmits, views feedback.
- **Parent** — read-only view of their child's grades/feedback; receives notifications.
- **Admin** — read-only oversight of all teachers' assignments/CBT school-wide.

## Core Flows
1. **Create** — Teacher creates an Assignment (free submission) or CBT (question set). CBT questions can be MCQ, True/False, or short-answer.
2. **Submit** — Student submits text / image / PDF, or answers CBT questions. Overdue CBTs show a badge and **cannot** be submitted.
3. **Mark** — Teacher opens a submission:
   - **Image:** pen, highlighter, and 📍comment pins placed at click point.
   - **PDF:** comments in a sidebar (tied to page).
   - Assigns a **score**, a **status** (Excellent / Satisfactory / Needs Revision), and general feedback.
   - **CBT auto-grading:** MCQ and True/False are scored automatically on submit; short-answer is held as "pending" until the teacher marks it.
4. **Return** — Teacher chooses **Save & Grade** (keep working) or **Return to Student** (notifies student **and** parent with grade + feedback).
5. **Feedback & Resubmit** — Student views grade, status, and inline comments. **Resubmit** is always available on returned work; the resubmit modal **pre-populates the previous answer**. Resubmission **replaces** the prior submission for re-marking. Teacher is notified.

## Key Acceptance Criteria (drive the data model)
- Image pins saved as **% coordinates** (relative to image dimensions), so they restore at the exact spot on re-open, regardless of screen size.
- Inline comments (pins, pen strokes, highlights, PDF sidebar notes) **persist and restore** across sessions.
- Return notifies **both** student and parent with grade + feedback.
- Resubmit modal pre-populates the previous answer; resubmission replaces the prior submission.
- MCQ/TF auto-graded (immediate score); short-answer pending until marked.
- Overdue CBT: badge shown; submission blocked.
- Admin sees all teachers' assignments/CBT.

## Data Model (high level — Supabase/Postgres tables, cached locally via Hive)
- `profiles` — { id (uid), role, name, parent_of? / child_of?, fcm_token? }
- `assignments` — { id, type: 'assignment' | 'cbt', title, description, due_date, created_by, class_id }
  - `questions` (CBT only, FK to assignment) — { id, assignment_id, type: 'mcq' | 'tf' | 'short', prompt, options[], correct_answer }
- `submissions` — { id, assignment_id, student_id, version, status: 'submitted' | 'returned' | 'resubmitted', answers[]/file_urls[], auto_score?, final_score?, status_label?, general_feedback?, submitted_at, returned_at }
  - `annotations` (FK to submission) — { id, submission_id, kind: 'pin' | 'pen' | 'highlight' | 'pdfComment', x_percent?, y_percent?, page?, path_points?, text, created_at }
- `notifications` — { id, user_id, type, ref_id, read, created_at } (in-app record; push handled separately)

Each of these maps to a feature under `domain/<feature>/entities` + `data/<feature>/models`, following the `auth` reference structure above.

## Notes / Out of Scope
- Focus of assessment is the **marking-with-inline-comments flow**; build the full M14 module if time allows.
- Handle empty/loading/error states for all async Supabase/Storage/Hive calls.
- Keep the data layer behind a repository interface (`domain/<feature>/repositories`) so the Supabase implementation could be swapped for a mock in tests.