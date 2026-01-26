const { setGlobalOptions } = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { Resend } = require("resend");

const resend = new Resend("re_cojh5xYR_CdgLnesc41A9geCo5ZGhHQuv");

setGlobalOptions({ maxInstances: 10 });

exports.sendOtp = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ error: "Email and OTP are required" });
    }

    const message = await resend.emails.send({
      from: "you@yourdomain.com",
      to: email,
      subject: "Your GlobalPay OTP",
      html: `<p>Your OTP is <strong>${otp}</strong>. It expires in 5 minutes.</p>`
    });

    logger.info(`OTP sent to ${email}`);

    return res.status(200).json({ success: true, messageId: message.id });
  } catch (err) {
    logger.error("Error sending OTP:", err);
    return res.status(500).json({ success: false, error: err.message });
  }
});
