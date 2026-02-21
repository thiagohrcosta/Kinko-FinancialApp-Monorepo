# KINKO — Ledger-Driven Fintech (Stripe-Powered Digital Banking Simulation)
<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/3558d184-3c8e-43a0-a7b6-6fb9ae41690e" />

## Project Overview

**KINKO** is a full-stack fintech platform composed of:

• A Rails-based financial engine exposing a secure REST API
• A cross-platform mobile application built with React Native

The system simulates the core architecture of a modern digital bank, implementing real financial domain principles rather than simplistic balance tracking.

Instead of storing mutable balances, KINKO operates on a ledger-first accounting model using double-entry bookkeeping. All monetary movements are recorded as immutable entries, and balances are derived mathematically from the ledger.

Stripe is used as the external payment processor, while KINKO maintains its own internal financial accounting engine.

This project was designed to demonstrate deep understanding of:

• Financial domain modeling
• Ledger systems
• Contract-driven obligations
• Secure payment orchestration
• Domain-driven design
• Backend architecture for fintech systems
