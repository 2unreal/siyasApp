"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.issueRefund = exports.recordPayment = exports.setManagerRole = exports.initializeOwner = exports.storage = exports.auth = exports.db = void 0;
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
// Initialize Firebase Admin SDK
if (!admin.apps.length) {
    admin.initializeApp();
}
exports.db = admin.firestore();
exports.auth = admin.auth();
exports.storage = admin.storage();
const BUSINESS_ID = 'house_of_siyas';
/**
 * Callable Function: Initialize or claim Owner role.
 */
exports.initializeOwner = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required to initialize owner.');
    }
    const uid = context.auth.uid;
    const callerPhone = context.auth.token.phone_number;
    const defaultOwnerPhone = '+916385876999';
    if (callerPhone !== defaultOwnerPhone && !data.bootstrapToken) {
        throw new functions.https.HttpsError('permission-denied', 'This phone number is not authorized as the primary Business Owner.');
    }
    await exports.auth.setCustomUserClaims(uid, {
        role: 'owner',
        businessId: BUSINESS_ID,
    });
    await exports.db.doc(`businesses/${BUSINESS_ID}/users/${uid}`).set({
        userId: uid,
        phone: callerPhone,
        role: 'owner',
        status: 'active',
        businessId: BUSINESS_ID,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { success: true, role: 'owner', businessId: BUSINESS_ID };
});
/**
 * Callable Function: Assign or update Manager role.
 */
exports.setManagerRole = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }
    if (context.auth.token.role !== 'owner') {
        throw new functions.https.HttpsError('permission-denied', 'Only the Business Owner can manage Manager roles.');
    }
    const { targetUid, name, phone, isActive } = data;
    if (!targetUid || !phone) {
        throw new functions.https.HttpsError('invalid-argument', 'targetUid and phone are required.');
    }
    const role = isActive === false ? 'inactive' : 'manager';
    await exports.auth.setCustomUserClaims(targetUid, {
        role: role,
        businessId: BUSINESS_ID,
    });
    await exports.db.doc(`businesses/${BUSINESS_ID}/users/${targetUid}`).set({
        userId: targetUid,
        name: name || '',
        phone: phone,
        role: role,
        status: isActive === false ? 'inactive' : 'active',
        businessId: BUSINESS_ID,
        updatedBy: context.auth.uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await exports.db.collection(`businesses/${BUSINESS_ID}/auditLogs`).add({
        action: isActive === false ? 'REVOKE_MANAGER' : 'SET_MANAGER',
        entity: 'user',
        entityId: targetUid,
        performedBy: context.auth.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: { targetPhone: phone, assignedRole: role },
    });
    return { success: true, targetUid, assignedRole: role };
});
/**
 * Callable Function: recordPayment
 * Secure Serverless Payment Processing Mechanism (Milestone 0 / Milestone 7).
 * Atomically reads protected financial summary, validates amount, calculates balance/credit,
 * records payment, and returns ONLY { newBalance, creditAmount } for the current step.
 */
exports.recordPayment = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required to record payments.');
    }
    const { entityType, entityId, amount, method, notes, customerId, studentId } = data;
    if (!entityType || !entityId || typeof amount !== 'number' || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid entityType, entityId, and positive amount are required.');
    }
    if (method !== 'cash' && method !== 'upi') {
        throw new functions.https.HttpsError('invalid-argument', 'Payment method must be cash or upi.');
    }
    const callerUid = context.auth.uid;
    const paymentId = exports.db.collection(`businesses/${BUSINESS_ID}/payments`).doc().id;
    return await exports.db.runTransaction(async (transaction) => {
        // 1. Read protected financial summary
        let summaryRef;
        if (entityType === 'order') {
            summaryRef = exports.db.doc(`businesses/${BUSINESS_ID}/orders/${entityId}/financials/summary`);
        }
        else if (entityType === 'class') {
            summaryRef = exports.db.doc(`businesses/${BUSINESS_ID}/students/${entityId}/financials/summary`);
        }
        else {
            throw new functions.https.HttpsError('invalid-argument', 'Unknown entityType');
        }
        const summaryDoc = await transaction.get(summaryRef);
        if (!summaryDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Financial record not found for this entity.');
        }
        const summaryData = summaryDoc.data();
        const orderTotal = summaryData.orderTotal || summaryData.totalFee || 0.0;
        const currentPaid = summaryData.totalPaid || summaryData.paidFee || 0.0;
        const currentCredit = summaryData.creditAmount || 0.0;
        const newTotalPaid = currentPaid + amount;
        let newBalance = 0.0;
        let newCredit = currentCredit;
        if (newTotalPaid > orderTotal) {
            // Overpayment: Balance is 0, excess added to customer credit
            newBalance = 0.0;
            const excess = newTotalPaid - orderTotal;
            newCredit += excess;
            // Record credit ledger document if customerId available
            if (customerId) {
                const creditDoc = exports.db.collection(`businesses/${BUSINESS_ID}/customerCredits`).doc();
                transaction.set(creditDoc, {
                    id: creditDoc.id,
                    customerId: customerId,
                    orderId: entityType === 'order' ? entityId : null,
                    amount: excess,
                    reason: `Overpayment on ${entityType} ${entityId}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    createdBy: callerUid,
                });
            }
        }
        else {
            newBalance = orderTotal - newTotalPaid;
        }
        // 2. Update protected financial summary
        transaction.update(summaryRef, {
            totalPaid: newTotalPaid,
            paidFee: newTotalPaid,
            balanceAmount: newBalance,
            balanceFee: newBalance,
            creditAmount: newCredit,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // 3. Write payment transaction record
        const paymentDoc = exports.db.doc(`businesses/${BUSINESS_ID}/payments/${paymentId}`);
        transaction.set(paymentDoc, {
            id: paymentId,
            entityType: entityType,
            entityId: entityId,
            customerId: customerId || null,
            studentId: studentId || null,
            amount: amount,
            method: method,
            receiptNumber: null, // Official receipts restricted until sync / generation
            paymentDate: admin.firestore.FieldValue.serverTimestamp(),
            recordedBy: callerUid,
            notes: notes || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // 4. Record audit log
        const auditDoc = exports.db.collection(`businesses/${BUSINESS_ID}/auditLogs`).doc();
        transaction.set(auditDoc, {
            action: 'PAYMENT_RECORDED',
            entity: entityType,
            entityId: entityId,
            performedBy: callerUid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: {
                paymentId: paymentId,
                amount: amount,
                method: method,
                resultingBalance: newBalance,
            },
        });
        // Return ONLY the resulting balance for this specific step!
        return {
            success: true,
            paymentId: paymentId,
            amountRecorded: amount,
            newBalance: newBalance,
            creditAmount: newCredit,
        };
    });
});
/**
 * Callable Function: issueRefund (Owner Only)
 */
exports.issueRefund = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }
    if (context.auth.token.role !== 'owner') {
        throw new functions.https.HttpsError('permission-denied', 'Only the Business Owner can issue refunds.');
    }
    const { entityType, entityId, amount, method, reason } = data;
    if (!entityType || !entityId || typeof amount !== 'number' || amount <= 0 || !reason) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid entityType, entityId, positive amount, and reason required.');
    }
    const callerUid = context.auth.uid;
    const refundId = exports.db.collection(`businesses/${BUSINESS_ID}/refunds`).doc().id;
    return await exports.db.runTransaction(async (transaction) => {
        const summaryRef = entityType === 'order'
            ? exports.db.doc(`businesses/${BUSINESS_ID}/orders/${entityId}/financials/summary`)
            : exports.db.doc(`businesses/${BUSINESS_ID}/students/${entityId}/financials/summary`);
        const summaryDoc = await transaction.get(summaryRef);
        if (!summaryDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Financial record not found.');
        }
        const summaryData = summaryDoc.data();
        const orderTotal = summaryData.orderTotal || summaryData.totalFee || 0.0;
        const currentPaid = summaryData.totalPaid || summaryData.paidFee || 0.0;
        const newTotalPaid = Math.max(0.0, currentPaid - amount);
        const newBalance = Math.max(0.0, orderTotal - newTotalPaid);
        transaction.update(summaryRef, {
            totalPaid: newTotalPaid,
            paidFee: newTotalPaid,
            balanceAmount: newBalance,
            balanceFee: newBalance,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const refundDoc = exports.db.doc(`businesses/${BUSINESS_ID}/refunds/${refundId}`);
        transaction.set(refundDoc, {
            id: refundId,
            entityType: entityType,
            entityId: entityId,
            amount: amount,
            method: method || 'cash',
            reason: reason,
            recordedBy: callerUid,
            refundDate: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const auditDoc = exports.db.collection(`businesses/${BUSINESS_ID}/auditLogs`).doc();
        transaction.set(auditDoc, {
            action: 'REFUND_ISSUED',
            entity: entityType,
            entityId: entityId,
            performedBy: callerUid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: { refundId: refundId, amount: amount, reason: reason },
        });
        return {
            success: true,
            refundId: refundId,
            newBalance: newBalance,
            newTotalPaid: newTotalPaid,
        };
    });
});
//# sourceMappingURL=index.js.map