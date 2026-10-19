# SIGNAL LOST: ENEMY REACTION & TRAVERSAL VERIFICATION REPORT

| Criterion | Expected Behavior | Observed Result | Status |
|---|---|---|---|
| Hit Hurt & Knockback | Hurt animation & velocity impulse | Knockback applied (160.0 px/s) + hurt anim | PASS |
| Poise Break Stagger | Poise <= 0 triggers stun/stagger | Depleted to 0; stun animation triggered | PASS |
| Statistical Evade | >= 1 evade in 20 hits at 35% rate | 6 evades recorded across 20 trials | PASS |
| Low-HP Behavior | Light enemy retreats; Brute enrages | Kenshi retreat=true, Brute enraged=true | PASS |
| Ledge Jump Traversal | Traverses to upper ledge within 6.0s | Reached upper platform in 0.48s | PASS |
| Upward Escape Leap | Attacks trigger vertical escape jump | Upward leap executed with vy=-440.0 px/s | PASS |
| Instant Death Accounting | Decrement instantly on death event | Count dropped 1->0 immediately prior to queue_free | PASS |
