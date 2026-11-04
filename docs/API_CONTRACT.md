# Amora REST API contract (for the Python backend)

The Flutter app already speaks this contract (see `lib/core/network/mock_interceptor.dart`,
which fakes it in memory). Build the FastAPI/Django backend to match it, then run the app with
`--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://<host>:8000/api/v1`.

- Base path: `/api/v1`. JSON, `snake_case` keys, ISO-8601 UTC timestamps.
- Auth: `Authorization: Bearer <access_token>` on everything except `/auth/login|register|refresh`.
- Errors: HTTP status + `{"detail": "human readable message"}` (FastAPI default works).
- Lists: `{"items": [...]}`.

## Auth
| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/auth/register` | `{name, email, password}` | `201 AuthSession` |
| POST | `/auth/login` | `{email, password}` | `AuthSession` (401 on bad credentials) |
| POST | `/auth/refresh` | `{refresh_token}` | `{access_token, refresh_token?}` |
| POST | `/auth/logout` | `{refresh_token}` | `204` |
| GET | `/auth/me` | – | `User` |

`AuthSession = {access_token, refresh_token, token_type: "bearer", user: User}`
`User = {id, name, email, is_onboarded}`

The app retries a request once after a 401 by calling `/auth/refresh`; if that fails it logs the user out.

## Profile
| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/profiles/me` | – | `Profile` |
| PATCH | `/profiles/me` | partial `Profile` fields, optional `complete_onboarding: true` | `Profile` |
| GET | `/profiles/{id}` | – | `Profile` |

```json
Profile = {
  "id": "u1", "name": "Ananya", "age": 25, "bio": "...",
  "gender": "man|woman|non_binary",
  "intent": "long_term|marriage|short_term|figuring_out",
  "job_title": "Designer", "school": null, "city": "Kochi",
  "distance_km": 3.2, "height_cm": 165, "is_verified": true,
  "photos": ["https://..."],
  "prompts": [{"question": "A perfect Sunday", "answer": "..."}],
  "interests": ["Travel", "Coffee"]
}
```
`complete_onboarding: true` must set the user's `is_onboarded` to true.
Photos are URLs for now; add `POST /profiles/me/photos` (multipart) later and the app will switch to Dio `FormData`.

## Discovery
| Method | Path | Body / Query | Response |
|---|---|---|---|
| GET | `/discovery/feed?limit=10` | – | `{items: Profile[]}` (exclude swiped, matched, blocked, and anyone outside preferences) |
| POST | `/discovery/swipe` | `{target_id, action: "like"\|"pass"\|"super_like", comment?}` | `{is_match: bool, match: Match\|null}` |
| POST | `/discovery/rewind` | – | `Profile` (undo the last **pass**; `409` if nothing to undo) |
| GET | `/discovery/preferences` | – | `Preferences` |
| PUT | `/discovery/preferences` | `Preferences` | `Preferences` |
| GET | `/likes/received` | – | `{items: ReceivedLike[]}` (people who liked me that I have not swiped on yet) |

`Preferences = {min_age, max_age, max_distance_km, interested_in: "men"|"women"|"everyone", verified_only}`
`ReceivedLike = {profile: Profile, liked_at, is_super_like, comment}`

A like on someone who already liked you creates a match and returns `is_match: true`.

## Matches & chat
| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/matches` | – | `{items: Match[]}` sorted by latest activity |
| DELETE | `/matches/{id}` | – | `204` (unmatch, deletes the conversation) |
| GET | `/matches/{id}/messages?before=<message_id>` | – | `{items: Message[]}` oldest first; marks incoming as read |
| POST | `/matches/{id}/messages` | `{text}` | `201 Message` |

```json
Match = {
  "id": "m1", "profile": Profile, "matched_at": "...",
  "last_message": Message|null, "unread_count": 0,
  "expires_at": "...|null",            // 24h expiry while there is no message; null afterwards
  "can_send_first_message": true       // set false to enforce a "first move" rule
}
Message = {"id", "match_id", "sender_id", "text", "sent_at", "is_read"}
```
The app polls messages every 5 s. A WebSocket (`/ws/chat`) can replace polling later.

## Relationship ("Us")
| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/relationship` | – | `Relationship` (or `{"status": "none"}`) |
| POST | `/relationship/request` | `{match_id}` | `Relationship` with `pending_sent` (`409` if already in one) |
| POST | `/relationship/respond` | `{accept: bool}` | `Relationship` (`active`) or `{"status": "none"}` |
| POST | `/relationship/end` | – | `204` |
| GET/POST | `/relationship/date-plans` | `{title, scheduled_at, place?, notes?}` | `{items: DatePlan[]}` / `201 DatePlan` |
| PATCH | `/relationship/date-plans/{id}` | `{status: "planned"\|"done"\|"cancelled"}` | `DatePlan` |
| GET/POST | `/relationship/memories` | `{title, date, note?, photo_url?}` | `{items: Memory[]}` / `201 Memory` |
| GET/POST | `/relationship/check-ins` | `{mood: "great"\|"good"\|"okay"\|"low"\|"upset", note?}` | `{items: CheckIn[]}` / `201 CheckIn` |

```json
Relationship = {"id", "status": "none|pending_sent|pending_received|active", "partner": Profile, "started_at": "...|null"}
DatePlan     = {"id", "title", "scheduled_at", "place", "notes", "status"}
Memory       = {"id", "title", "date", "note", "photo_url"}
CheckIn      = {"id", "user_id", "mood", "note", "created_at"}
```
`status` is from the caller's point of view: the requester sees `pending_sent`, the partner sees `pending_received`.
Date plans, memories and check-ins belong to the relationship and are visible to both partners.

## Suggested backend extras (not yet called by the app)
Block/report users, photo verification, push notifications (FCM tokens), and a WebSocket for chat.
