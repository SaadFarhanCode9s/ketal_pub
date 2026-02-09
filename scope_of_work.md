Milestone 1: ElementX iOS fork + Synapse stack (OTP Auth + Audio/Video call buttons)
Overview 
Deliver an end-to-end working prototype of a rebranded custom ElementX iOS fork (working name: “ketal”) plus a self-hosted Synapse homeserver stack on a VPS. Scope is limited to: (1) branding changes (app name, icon, splash screen, and removal/replacement of user-visible ElementX references), (2) simplified login flow using passwordless email OTP authentication UX, and (3) adding an Audio Call button next to the existing Video Call (same underlying call flow; different initial configuration only)
iOS client scope
Modify the ElementX iOS client to implement a unified email OTP login/sign up flow (web-based auth flow) in WebView bottom sheet modal.
Implement Audio call button alongside the Video call one with only difference in initial settings:
Audio Call: camera off by default; handset/earpiece mode by default.
Video Call: camera on by default; speaker mode by default.
Server stack scope
Deploy Keycloak (via Docker Compose) authentication service and Synapse homeserver (via Synapse Ansible playbook) on the same VPS.
Configure Keycloak for end-to-end Email OTP capability (we recommend Resend for SMTP). Customize login flow pages to match the provided Figma.
Configure the playbook to install and use:
synapse-admin and element-admin
Real-time audio and video calling dependencies
Matrix Authentication Service (MAS) integrated with Keycloak as the upstream IdP and use passwordless OTP flow
Other requirements
The iOS client fork must remain close to upstream ElementX and remain fully functional.
You are required to deploy the stack on a custom domain of your choice and use your own accounts for all required hosting and cloud services.
The app domain (e.g. myapp.com), auth (auth.myapp.com for Keycloak) and homeserver (matrix.myapp.com for Synapse) domains should be different; homeserver URL must not be hardcoded in app – use .well-known for homeserver discovery. In general, use the provided Ansible playbook best practices.
No changes to Matrix cryptographic/E2EE/key procedures and other core protocol/security behaviours.
Element Web app should not require any changes and should be fully functioning.
On first-time user login (account creation), prompt user to choose a username leveraging Synapse/MAS existing APIs and flows keeping close to chosen UI. 
Follow Matrix/Synapse/Keycloak security best practices ensuring certificates are correctly provisioned; sensitive endpoints (e.g. Synapse admin APIs) are not exposed directly to the client and are appropriately protected; new users created only after email verification (correctly input OTP).
Deliverables and acceptance
Deploy server stack (Synapse + MAS + Keycloak + required supporting services) on 1 VPS and internal TestFlight build uploaded under the developer’s Apple developer account, with the client invited for verification.
Provide 2 private GitHub repositories:
ElementX iOS fork source code according to described specifications
Server repository with code and scripts required to re-create the working stack
A concise README in each repo that allows the client to (a) run/deploy the server stack and (b) build/run the iOS app against it, plus a short “happy path” test showing: user can sign up/sign in via email OTP, can send/receive messages, and can place Audio Call and Video Call end-to-end.
The expected result is a fully working custom branded ElementX app with a Synapse server deployed on a VPS. The app is expected to support hundreds of users with one simplified sign-in/sign-up flow via email OTP flow.
Resources
Figma
ElementX iOS Client
Synapse Ansible playbook
Keycloak + Keycloakify + keycloak-magic-link

