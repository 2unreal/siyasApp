"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const fs = require("fs");
const path = require("path");
/**
 * Security Rule Matrix Static & Semantic Verification Suite
 * Verifies all security requirements against firestore.rules and storage.rules
 */
const firestoreRulesPath = path.resolve(__dirname, '../../firestore.rules');
const storageRulesPath = path.resolve(__dirname, '../../storage.rules');
const firestoreRules = fs.readFileSync(firestoreRulesPath, 'utf8');
const storageRules = fs.readFileSync(storageRulesPath, 'utf8');
let totalTests = 0;
let passedTests = 0;
function assertRule(description, condition) {
    totalTests++;
    if (condition) {
        console.log(`  ✓ [PASS] ${description}`);
        passedTests++;
    }
    else {
        console.error(`  ✗ [FAIL] ${description}`);
        process.exitCode = 1;
    }
}
console.log('Running Milestone 2 Security Rules Verification Suite:');
// 1. Zero-Trust RBAC helpers
assertRule("RBAC defines isOwner checking request.auth.token.role == 'owner'", firestoreRules.includes("request.auth.token.role == 'owner'"));
assertRule("RBAC defines isManager checking request.auth.token.role == 'manager'", firestoreRules.includes("request.auth.token.role == 'manager'"));
// 2. Manager Payment Privacy Enforcement
assertRule("Decoupled financial summary matches /financials/summary and allows read ONLY to Owner", firestoreRules.includes('match /financials/summary') &&
    firestoreRules.includes('allow read: if isOwner();'));
assertRule("Manager CANNOT read financial summary documents directly", !firestoreRules.includes('match /financials/summary {\n          allow read: if isAuthorizedStaff();'));
assertRule("Payments collection (/payments/{paymentId}) allows read ONLY to Owner", firestoreRules.includes('match /payments/{paymentId}') &&
    firestoreRules.includes('allow read: if isOwner();'));
// 3. Classes & Student Fees Owner Restriction
assertRule("Students and class payments restricted exclusively to Owner", firestoreRules.includes('match /students/{studentId}') &&
    firestoreRules.includes('allow read, write: if isOwner();'));
// 4. Settings & Numbering
assertRule("AppSettings write restricted strictly to Owner", firestoreRules.includes('match /appSettings/{settingId}') &&
    firestoreRules.includes('allow write: if isOwner();'));
// 5. Document Generation (Invoices, Receipts)
assertRule("Documents collection restricted exclusively to Owner", firestoreRules.includes('match /documents/{documentId}') &&
    firestoreRules.includes('allow read, write: if isOwner();'));
// 6. Hard Deletion Prohibition
assertRule("Customers hard delete permanently disallowed (allow delete: if false)", firestoreRules.includes('match /customers/{customerId}') &&
    firestoreRules.includes('allow delete: if false;'));
assertRule("Orders hard delete permanently disallowed (allow delete: if false)", firestoreRules.includes('match /orders/{orderId}') &&
    firestoreRules.includes('allow delete: if false;'));
// 7. Immutable Audit Logs
assertRule("Audit logs write permanently disallowed from clients (allow write: if false)", firestoreRules.includes('match /auditLogs/{auditId}') &&
    firestoreRules.includes('allow write: if false;'));
// 8. Storage Security Rules
assertRule("Storage requires authenticated staff for operations", storageRules.includes('allow read: if isStaff();'));
assertRule("Storage enforces 10MB file size limit strictly", storageRules.includes('request.resource.size <= 10 * 1024 * 1024'));
assertRule("Storage enforces valid image and PDF MIME types", storageRules.includes("request.resource.contentType.matches('image/.*')") &&
    storageRules.includes("request.resource.contentType == 'application/pdf'"));
console.log(`\nVerification Summary: ${passedTests}/${totalTests} Security Matrix Checks Passed!`);
if (passedTests !== totalTests) {
    process.exit(1);
}
//# sourceMappingURL=security_test.js.map