
AgentDriveIQ
AI-Powered Test Drive Platform


Solution Overview
Electra Cars — End-to-End Intelligent Test Drive Booking on Salesforce

Platform	Salesforce + Agentforce
AI Technology	RAG, Generative AI, Voice
Channels	Web, WhatsApp, Voice

Powered by Salesforce Agentforce & Data Cloud
 
 
Table of Contents
Table of Contents	2
1. Executive Summary	3
2. Solution Overview	4
2.1 High-Level Architecture	4
3. Customer Agent Detailed Design	5
3.1 Entry Points & Channel Strategy	5
3.2 Vehicle Intelligence RAG with Data Cloud	5
3.3 Lead Management	5
3.4 Test Drive Booking Flow	6
3.5 Reschedule & Cancellation Flows	6
4. Sales Rep Agent Detailed Design (Voice)	7
4.1 Authentication	7
4.2 Flow 1 View Schedule	7
4.3 Flow 2 Update Test Drive Status	7
4.4 Flow 3 Emergency Reassignment	7
5. Post-Drive Feedback & AI Analysis	8
5.1 Feedback Collection	8
5.2 Generative AI Analysis (Prompt Builder)	8
5.3 CRM Record Updates	8
6. Salesforce Data Model	9
7. Technical Architecture & Salesforce Standards	10
7.1 Platform Foundation	10
7.2 Development Standards	10
7.3 Integration Points	10
8. Reporting & Analytics	11
9. Key Differentiators	11
10. Future Enhancements & Roadmap	12

 
1. Executive Summary
AgentDriveIQ is a Salesforce-native, AI-powered test drive management platform built for Electra Cars. It eliminates manual handoffs between booking channels and back-office systems by deploying two purpose-built Agentforce agents one serving customers across web and WhatsApp, and one serving sales representatives over voice. The system automates the full lifecycle: inquiry, vehicle recommendation, showroom matching, appointment booking, test drive execution, lead conversion, and post-drive feedback analysis.

Core Value Proposition
Zero manual intervention from customer inquiry to CRM record creation, lead conversion, and next-best-action generation — all orchestrated by AI agents on Salesforce's unified data platform.

Metric	Before	After (AgentDriveIQ)
Booking Channels	Web based long form	Web, WhatsApp, Voice
Lead Creation	Web to lead	Automated via Agent
Showroom Matching	Rep knowledge	AI geo-matching
Slot Selection	Manual calendar	FSL API + timezone
Lead Conversion	Manual post-drive	Auto on completion
Feedback Loop	None / ad hoc	AI-scored, NBA-driven

 
2. Solution Overview
AgentDriveIQ is built on Salesforce Headless 360 as the agent runtime. The platform integrates Agentforce, Data Cloud, Field Service Lightning (FSL), and Experience Sites into a cohesive, fully automated workflow. Two AI agents handle distinct personas — customers and internal sales representatives — with no overlap and no manual handoff required.

2.1 High-Level Architecture
Component	Role & Technology
Agentforce service Agent	Handles all customer interactions on Web & WhatsApp. Orchestrates vehicle Q&A, lead creation, showroom matching, appointment booking, reschedule, and cancellation.
Agentforce service Agent (Voice)	Handles inbound calls from sales reps. Supports schedule viewing, test drive status updates, and emergency reassignment.
Salesforce Data Cloud	Hosts vehicle brochures; powers RAG-based vehicle Q&A. Single source of truth for all customer and vehicle data.
Field Service Lightning (FSL)	Manages service appointments, resource availability, territory matching, and skill-based scheduling via getAvailableCandidates API.
Prompt Builder (GenAI Tool)	Resolves customer pincode to lat/long; enriches territory context; generates next-best-action recommendations from feedback.
Salesforce Experience Sites	Hosts the customer feedback form and the dealer/company portal.
Salesforce Reports & Dashboards	Service rep performance (monthly test drives); dealer performance (quarterly opp win/loss).











3. Customer Agent Detailed Design
 
3.1 Entry Points & Channel Strategy
Customers interact with the Customer Agent through two channels:
•	Electra Cars Website embedded chat widget powered by Agentforce
•	WhatsApp via Salesforce's native WhatsApp integration with Agentforce
Both channels share the same agent logic and Salesforce data model, ensuring consistency across touchpoints.

3.2 Vehicle Intelligence RAG with Data Cloud
The agent is backed by a Retrieval-Augmented Generation (RAG) pipeline powered by Salesforce Data Cloud:
•	All vehicle brochures are ingested into Data Cloud as unstructured documents.
•	When a customer asks a vehicle-related question (e.g., "Suggest a car for a family of 5"), the agent queries Data Cloud's vector search to retrieve the most relevant brochure sections.
•	The retrieved context is passed to the generative AI model alongside the customer question, producing accurate, grounded vehicle recommendations.
•	Vehicle Definition records in Salesforce serve as the structured inventory catalog, surfacing full model details when a requested vehicle is not available in showroom inventory.

RAG Flow Example
Customer: "Which car suits a family of 5 with weekend trips?" → Agent queries Data Cloud vector index → Retrieves relevant brochure content for SUV/MPV models → Generative AI synthesises a personalised recommendation with seating, boot space, and safety rating details.

3.3 Lead Management
The agent collects the following data points before creating or matching a Lead:
•	Full Name (First + Last)
•	Phone Number
•	Email Address
•	Contact Number (alternate, if different)
•	Pincode / ZIP Code
Lead deduplication is keyed on Phone + Last Name. If a matching Lead already exists, the agent reuses the record. If not, a new Lead is created automatically no rep action required.

3.4 Test Drive Booking Flow
1.	Customer initiates interaction via Web/WhatsApp → request handled by AI Agent (Agentforce).
2.	Agent captures basic details (Name, Phone, Email, Zipcode) → triggers Flow to:
o	Match existing Lead using Phone + Last Name
o	Create new Lead if no match found
3.	Agent prompts for preferred vehicle → user input captured and validated.
4.	Backend checks vehicle availability:
o	If available in showroom inventory → proceed
o	If not available → fetch full vehicle list from Vehicle Definition (via Data Cloud / knowledge retrieval) → present to user
5.	System performs duplicate validation:
o	Query Test Drive records for Lead + Vehicle combination
o	If exists → Agent prompts user to Reschedule or Cancel instead of creating duplicate
6.	Agent initiates showroom resolution:
o	Pincode passed to Prompt Builder GenAI tool → converted to latitude/longitude
o	Data Cloud + prompt template retrieval enriches territory data
o	Nearest Service Territory (showroom) identified
o	Agent confirms showroom with customer
7.	Agent requests preferred date/time from user → ensures future date validation.
8.	Backend invokes FSL getAvailableCandidates API:
o	Filters applied:
	Service Territory
	Service Resources
	Resource Skills & Skill Levels
o	Returns available slots
9.	System performs timezone normalization:
o	Converts all returned datetime slots into customer’s local timezone
o	Filters edge cases (past/invalid slots)
10.	Agent presents available time slots → user selects preferred slot.
11.	Booking confirmation triggers backend orchestration:
•	Create Test Drive record (linked to Lead)
•	Create Service Appointment:
o	Assign vehicle
o	Assign Service Resource (Sales Rep)
o	Associate Service Territory
•	Ensure no double-booking via validation checks
12.	System generates confirmation response:
•	Booking details (date, time, showroom, sales rep)
•	Vehicle brochure link (from Data Cloud)
•	Sent via chat/WhatsApp
13.	Post-booking automation:
•	Flow schedules 24-hour reminder email to customer
14.	On scheduled date:
•	Sales Rep executes test drive
•	Updates Service Appointment status → synced with Test Drive record
15.	Upon completion:
•	System triggers feedback email via Flow
•	Customer accesses Experience Cloud site and submits feedback
16.	Feedback processing:
•	Store rating, comments
•	Calculate purchase probability / success rate
•	Generate recommendation field on Test Drive
17.	Backend automation:
•	Create Task on Opportunity (Next Best Action for sales rep)
18.	Lead lifecycle completion:
•	Lead converted to Contact
•	Opportunity automatically created
19.	Reporting & analytics:
•	Data captured for dashboards:
o	Sales rep performance
o	Dealer conversion rates
o	Test drive success metrics

3.5 Reschedule & Cancellation Flows
Both flows are fully handled by the Customer Agent as discrete scenarios:

Step	Cancellation	Reschedule
1. Identify user	If user info not collected, agent requests it first.	Same: collect user info if missing.
2. Retrieve booking	Agent identifies existing Test Drive and presents details for customer confirmation.	Same: display current booking for confirmation.
3. Action	Agent cancels the Test Drive and associated Service Appointment. No further action.	Agent re-runs the slot flow. Customer picks a new slot. Agent updates Test Drive and Service Appointment records.


 
4. Sales Rep Agent Detailed Design (Voice)
Sales representatives call in via Agentforce Voice rather than logging into Salesforce manually. The agent authenticates the rep by matching their inbound phone number to a Service Resource record. Three distinct flows are available:

4.1 Authentication
•	Inbound call number is matched against Service Resource records in Salesforce.
•	If matched, the agent greets the rep by name and presents the three flow options.
•	If not matched, the agent requests to call with the registered mobile number.

4.2 Flow 1 View Schedule
•	Agent fetches all Test Drives assigned to the authenticated rep for the current day.
•	Results are summarised and read back over voice: customer name, vehicle, time.
•	Security guard: if a rep references a Test Drive number not tagged to them, the agent rejects the query and prompts for a valid one.

4.3 Flow 2 Update Test Drive Status

Action	System Behaviour
Mark Complete (with comments)	Comments stored on Test Drive record. Service Appointment status synced. Lead converted to Account, Contact, and Opportunity (dedup-safe). Test Drive linked to Account and Opportunity. Feedback email auto-fired with link to Experience Site form.
Mark Cancelled (e.g., no-show)	Test Drive and Service Appointment marked cancelled. No further CRM actions triggered.

4.4 Flow 3 Emergency Reassignment
1.	Rep requests reassignment (e.g., emergency, illness).
2.	Agent calls getAvailableCandidates API across all reps in the same territory.
3.	Candidates are filtered by matching skill and skill level.
4.	Reassignment is made to the first available matching rep.
5.	The newly assigned rep receives a Salesforce custom notification.
6.	If no rep is available at that slot, the original rep is told to escalate to their manager.

 
5. Post-Drive Feedback & AI Analysis
Upon Test Drive completion, the platform closes the loop with an automated, AI-driven feedback and next-best-action cycle:

5.1 Feedback Collection
•	A feedback email is automatically sent to the customer when a rep marks the drive complete.
•	The email contains a personalised link to the Experience Site feedback form.
•	Responses are submitted directly into Salesforce via the Experience Site.

5.2 Generative AI Analysis (Prompt Builder)
•	On feedback submission, a Prompt Builder template analyses the customer's response.
•	The AI intelligently scores the purchase success likelihood (propensity to buy).
•	A recommended next-best action for the sales rep is generated (e.g., schedule a follow-up call, offer a financing demo, initiate a trade-in assessment).

5.3 CRM Record Updates
•	Purchase success rate and next-best-action recommendation are stored on the completed Test Drive record.
•	The system automatically creates a Next Best Action task on the corresponding open Opportunity.
•	The sales rep sees the recommended action on the Opportunity record no manual interpretation required.

AI Intelligence in Action
A customer who gives a 9/10 rating and mentions "very happy with the space and comfort" triggers a next-best-action of: "High purchase intent detected. Recommend scheduling a finance consultation within 48 hours and presenting the extended warranty package."

 
6. Salesforce Data Model
The following Salesforce objects form the core data model for AgentDriveIQ:

Object	Purpose	Key Fields / Notes
Lead	Prospective customer record	Phone + Last Name (dedup key); linked to Test Drive
Account	Converted customer account	Created on Test Drive completion; dedup-safe
Contact	Converted customer contact	Created on conversion; linked to Account
Opportunity	Sales pipeline record	Created on conversion; linked to Test Drive and Account
Test Drive (Custom)	Core booking record	Links Lead/Account, Vehicle, Showroom, Service Appointment
Service Appointment (FSL)	Field service slot	Assigns vehicle + sales rep; prevents double-booking
Service Resource (FSL)	Sales rep or vehicle	Matched by skill, territory, availability
Vehicle Definition (Custom)	Vehicle catalog	Full model list for inventory fallback
Feedback Response (Custom)	Post-drive feedback	Stores AI score and NBA recommendation

 
7. Technical Architecture & Salesforce Standards
7.1 Platform Foundation
•	Salesforce Headless 360 as the agent runtime for both Customer and Sales Rep agents
•	Agentforce for natural language understanding, flow orchestration, and voice processing
•	Data Cloud for vector-based RAG retrieval and unified customer data profile
•	Field Service Lightning for appointment scheduling, resource management, and territory operations
•	Experience Sites for the customer feedback form and standard company portal

7.2 Development Standards
•	All Apex classes have complete test coverage meeting Salesforce deployment standards
•	Custom Labels used throughout for all configurable string values and UI text
•	Custom Metadata Types used for environment-specific configuration (endpoints, thresholds, template IDs)
•	Prompt Builder templates used for all GenAI interactions (pincode resolution, NBA generation)
•	Flow-based automation for email triggers, record updates, and reminder scheduling

7.3 Integration Points
Integration	Details
FSL getAvailableCandidates API	Called during booking and reassignment to fetch available reps/vehicles filtered by territory, skill, and time window.
Prompt Builder (Geocoding)	Resolves customer pincode to lat/long for nearest showroom identification.
Data Cloud Vector Search	Powers RAG retrieval for vehicle brochure Q&A.
Data Cloud Web Search	Enriches territory details via prompt templates during showroom matching.
Salesforce Notifications API	Sends custom in-app notifications to newly assigned reps on emergency reassignment.
Email (Salesforce Flow)	Sends booking confirmation, 24-hour reminder, and post-drive feedback emails.

 
8. Reporting & Analytics
AgentDriveIQ includes purpose-built reports for two stakeholder audiences:

Report	Description
Service Rep Performance (Monthly)	Tracks test drive count per rep, completion vs. cancellation rate, and average AI purchase success score per rep. Refreshed monthly.
Dealer Performance (Quarterly)	Tracks opportunity win/loss by dealership, vehicle model, and territory. Supports quarterly business reviews and resource planning.

9. Key Differentiators

Differentiator	How AgentDriveIQ Delivers It
Zero manual handoffs	Both agents operate end-to-end: from first customer message to CRM record, appointment, and next-best-action with no rep intervention required.
Intelligent duplicate prevention	Lead dedup on Phone + Last Name; Test Drive dedup on Lead + Vehicle; rep reassignment prevents skill mismatches.
Contextual AI recommendations	RAG-grounded vehicle Q&A and AI-scored purchase propensity ensure every interaction is data-driven, not scripted.
Timezone-aware scheduling	All slot datetimes converted to customer local timezone before display — critical for multi-region dealerships.
Salesforce-native architecture	No external dependencies. All data, logic, AI, and automation runs within the Salesforce trust boundary.
360-degree feedback loop	Automated feedback collection, AI analysis, and NBA generation close the sales cycle without rep effort.

 
10. Future Enhancements & Roadmap
The following enhancements are planned for post-hackathon iterations:

•	Enhanced Sales Rep Experience
Provide daily, next-day, and weekly schedules along with real-time traffic insights to help reps plan and optimize their day efficiently.
•	 Personalized Recommendations with Data Cloud
Deliver intelligent vehicle suggestions based on customer history, including past test drives and preferences.
•	 Real-Time Customer Engagement
Go beyond email reminders by enabling instant WhatsApp and SMS notifications for bookings, updates, and reminders

