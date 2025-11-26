const mongoose = require("mongoose");

const participantConversationSchema = new mongoose.Schema(
  {
    conversation_id: {
      type: String,
      ref: "Conversation",
      required: true,
    },

    employee_id: {
      type: String,
      ref: "Employee",
      required: true,
    },

    role_conversation_id: {
      type: String,
    },

    joined_at: {
      type: Date,
      default: Date.now,
    },

    last_seen: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

const ParticipantConversation = mongoose.model(
  "Participant_Conversation",
  participantConversationSchema
);
module.exports = ParticipantConversation;
