'use strict'

const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase)
exports.sendNewMessageNotification = functions.database.ref('/users/{uid}/unreadMessages/{messageKey}').onCreate((event) => {
    const uid = event.params.uid
    const message = event.data.val()
    console.log('New message: ', message)
    const getRegistrationTokensPromise = admin.database().ref(`/users/${uid}/registrationTokens`).once('value')
    const getUnreadMessageCountPromise = admin.database().ref(`/users/${uid}/unreadMessages`).once('value')
    return Promise.all([getRegistrationTokensPromise, getUnreadMessageCountPromise]).then((results) => {
        const registrationTokensSnapshot = results[0]
        if (!registrationTokensSnapshot.exists()) {
            return console.log('There are no notification tokens to send to.')
        }
        const unreadMessageCountSnapshot = results[1]
        const unreadMessageCount = unreadMessageCountSnapshot.numChildren()
        const payload = {
            notification: {
                badge: unreadMessageCount.toString(),
                body: message.senderDisplayName + ': ' + message.text,
                parentConvoKey: message.parentConvoKey,
                sound: 'newMessage.wav'
            }
        }
        const tokens = Object.keys(registrationTokensSnapshot.val())
        return admin.messaging().sendToDevice(tokens, payload).then((response) => {
            const removeTokenPromises = []
            response.results.forEach((result, index) => {
                const error = result.error
                const token = tokens[index]
                if (error) {
                    if (error.code === 'messaging/invalid-registration-token' || error.code === 'messaging/registration-token-not-registered') {
                        removeTokenPromises.push(registrationTokensSnapshot.ref.child(token).remove())
                        console.log('Removing invalid registration token: ', token)
                    } else {
                        console.error('Failure sending notification to registration token: ', token, error)
                    }
                } else {
                    console.log('Sent new message notification to registration token: ', token)
                }
            })
            return Promise.all(removeTokenPromises)
        })
    })
})