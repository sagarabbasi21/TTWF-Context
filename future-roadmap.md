# Future Roadmap — Teach The World Foundation
> Created: 2026-03-31
> Scope: Features beyond MVP and v1.1 — identified based on project domain, existing architecture, and logical growth areas

---

## Roadmap Phases

```
MVP        → Core system live (schools, students, devices, attendance)
v1.1       → Holidays, Regions, IT Logs, Dashboard refresh
v2.0       → Analytics, Reporting, Notifications
v3.0       → Parent Portal, Teacher Module, Content Management
v4.0       → AI/ML features, Advanced Integrations
```

---

## v2.0 — Analytics & Operational Intelligence

### 1. Advanced Dashboard & Reporting
Current dashboard shows basic counts. Expand to:
- **School performance heatmap** on Pakistan map (Leaflet already in project)
- **Attendance trends** per school/district/region — daily, weekly, monthly
- **Device sync health** board — which schools haven't synced in X days
- **Student dropout tracker** — reason_for_inactive breakdown by area
- **Donor impact report** — schools/students per project per donor
- Exportable PDF/Excel reports per module
- **Scheduled reports** emailed to stakeholders automatically

### 2. Competency & Learning Progress Dashboard
The `competency_mapping` app already tracks eggs/levels/stars. Build visibility:
- Per-student competency progress timeline
- Class-level competency heatmap (which egg/level most students are stuck on)
- Subject-wise completion rates across schools
- Comparative analysis between schools in same cluster/region

### 3. Audit Log / Change History
Track who changed what and when across all modules:
- `AuditLog` table: user, model, record_id, action (create/update/delete), old_value, new_value, timestamp
- UI: filter by user, module, date range
- Immutable — no edits/deletes on audit records
- Useful for compliance and accountability

---

## v2.1 — Communication & Notifications

### 4. In-App Notification System
- Notify admins when: device hasn't synced in 3+ days, student marked inactive, new role pending approval
- Notification bell in header (already has header.html)
- Mark read/unread, notification history

### 5. Email & SMS Alerts
- Send alerts to field coordinators when schools miss attendance thresholds
- Automated weekly summary emails to managers
- SMS integration (e.g., Twilio or local Pakistan SMS gateway) for field staff without reliable email access

### 6. Bulk Communication Tool
- Send announcements to all users in a specific district/region/cluster
- Message templates for common communications
- Delivery tracking (sent/read)

---

## v3.0 — Extended User Roles

### 7. Teacher Module
Currently only admin-side. Add teacher-facing features:
- Teacher profile (linked to school, subject, grade)
- Teacher attendance (separate from student attendance)
- Lesson plan tracking
- Teacher performance metrics (students progressing under them)

### 8. Parent / Guardian Portal
Read-only portal for parents:
- View child's attendance record
- View learning progress (competency level)
- Receive SMS/email alerts for absences
- Simple mobile-friendly UI (separate from admin dashboard)
- Login via student UID + parent mobile number (no email needed)

### 9. Field Coordinator Mobile App (Web PWA)
For field staff visiting schools:
- Quick school check-in (GPS-tagged visit log)
- Device health check (mark devices as working/faulty)
- Photo uploads of school/device issues
- Offline-capable (sync when internet available)
- Separate from tablet app — this is supervisor-facing

---

## v3.1 — Content & Curriculum Management

### 10. Learning Content Management (CMS)
Currently `competency_mapping` tracks curriculum structure but content lives on tablets. Add:
- Upload and version learning content (videos, audio, images) per star/activity
- Content approval workflow (draft → review → published)
- Content version history — know which version is on which device
- Map content to: Subject → Egg → Level → Star

### 11. Assessment / Quiz Builder
- Create quizzes linked to learning standards
- Assign assessments to grades/schools
- Auto-score (MCQ) + manual score (subjective)
- Results feed into competency scores

### 12. Curriculum Calendar
- Academic year setup per school
- Map subjects/chapters to weeks/months
- Auto-flag if school is behind curriculum schedule based on competency data

---

## v3.2 — School Operations

### 13. Fee / Stipend Management
For programs that provide student stipends or charge school fees:
- Define fee structures per school type or project
- Track payments (paid/pending/overdue)
- Generate receipts
- Donor funding vs fee revenue breakdown

### 14. Asset / Inventory Management
Beyond devices — track all physical assets per school:
- Furniture, books, supplies
- Asset condition tracking (good/damaged/lost)
- Replacement requests workflow
- Depreciation tracking

### 15. Staff Management
- Non-teacher staff (janitors, security, admin staff) per school
- Staff attendance
- Contract types (permanent/contract/volunteer)
- Document storage (CNIC, contract scans)

### 16. School Visit & Inspection Module
- Schedule supervisor visits to schools
- Standardized inspection checklist (building condition, device health, attendance books)
- Photo evidence upload
- Scoring and pass/fail per school
- Follow-up action items with deadlines

---

## v4.0 — AI / ML Features

### 17. Dropout Risk Prediction
Using existing data (attendance_sessions, competency progress, inactivity history):
- ML model to flag students at high risk of dropping out
- Risk score per student (low/medium/high)
- Early intervention alerts to field coordinators
- Retrain model quarterly with new data

### 18. Attendance Anomaly Detection
- Auto-detect unusual patterns: school with 0 attendance for 3 days (holiday? device issue? closure?)
- Device sync anomaly: tablet syncing at 2 AM (spoofed data?)
- Flag for manual review

### 19. Smart School Clustering
- Suggest optimal cluster assignments based on geographic proximity (using lat/lng already in schema)
- Identify under-served areas (few schools, high population)
- Visualize coverage gaps on map

### 20. Natural Language Reports
- Admin types: "Show me attendance for Karachi schools last month"
- System generates the filtered report automatically
- Built on top of existing filter/API infrastructure

---

## v4.1 — Integrations

### 21. Government / EMIS Integration
Pakistan's Education Management Information System (EMIS):
- Export school/student data in EMIS-compatible format
- Sync school registration numbers (SEF code already in schema)
- Auto-populate school data from EMIS for new registrations

### 22. Donor CRM Integration
- Sync donor data with external CRMs (Salesforce, HubSpot)
- Donation tracking beyond project assignment
- Donor communication history
- Grant reporting templates for international donors (USAID, DFID format)

### 23. Financial System Integration
- Connect with accounting software (QuickBooks, Xero)
- Project budget vs actual spend tracking
- Cost-per-student calculations per project

### 24. WhatsApp Business API
- Send attendance summaries to school supervisors on WhatsApp
- Receive "school closed today" confirmations from principals via WhatsApp
- Common in Pakistan field operations

---

## v4.2 — Platform & Infrastructure

### 25. Multi-Tenant Architecture
Currently single-tenant (one organization). If the platform is licensed to other NGOs:
- Organization-level data isolation
- Per-tenant branding (logo, colors)
- Per-tenant feature flags
- Centralized super-admin panel

### 26. Offline-First Admin Dashboard
For areas with poor internet:
- Service Worker + IndexedDB for PWA
- Queue writes when offline, sync when online
- Conflict resolution strategy
- Show "last synced" timestamp

### 27. API for Third-Party Developers
- Public REST API with API key management
- Rate limiting per key
- Swagger/OpenAPI documentation (DRF already supports this)
- Webhook support for real-time event push
- Useful for partner NGOs or government departments

### 28. Advanced Role & Permission System
Current system has module-level CRUD permissions. Extend to:
- **Row-level security** — user A can only see schools in their cluster
- **Field-level permissions** — some roles see student DOB, others don't
- **Time-based access** — temporary access grants with expiry
- **Delegation** — manager can delegate their access to a deputy

---

## Summary by Priority

| Phase | Features | Trigger to Start |
|-------|----------|-----------------|
| **v1.1** | Holidays, Regions, IT Logs, Dashboard | After MVP stable |
| **v2.0** | Advanced reports, Competency dashboard, Audit log | After v1.1 live + user feedback |
| **v2.1** | Notifications, Email/SMS alerts | After v2.0 |
| **v3.0** | Teacher module, Parent portal, Field coordinator app | Stakeholder demand |
| **v3.1** | CMS, Assessments, Curriculum calendar | Content team ready |
| **v3.2** | Fee management, Assets, Staff, Inspections | Operations team demand |
| **v4.0** | AI/ML features | Sufficient data collected (6+ months) |
| **v4.1** | EMIS, Donor CRM, WhatsApp | Partnership agreements |
| **v4.2** | Multi-tenant, Offline PWA, Public API | Scale/licensing decision |
