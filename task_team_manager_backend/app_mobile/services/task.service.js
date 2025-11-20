const Task = require("../models/task.model");
const fs = require("fs");
const path = require("path");

class TaskService {
  extractTaskData(payload) {
    const task = {
      task_id: payload.task_id,
      task_name: payload.task_name,
      project_id: payload.project_id,
      task_type_id: payload.task_type_id,
      parent_task_id: payload.parent_task_id,
      assigned_to: payload.assigned_to,
      description: payload.description,
      start_date: payload.start_date,
      end_date: payload.end_date,
      priority: payload.priority,
      status: payload.status,
    };

    Object.keys(task).forEach(
      (key) => task[key] === undefined && delete task[key]
    );
    return task;
  }

  extractAttachmentData(file, uploadedBy) {
    return {
      attachment_id: Date.now() + "-" + Math.round(Math.random() * 1e9),
      file_name: file.originalname || file.filename,
      file_url: file.path || file.location,
      file_type: file.mimetype,
      size: file.size,
      uploaded_at: new Date(),
      uploaded_by: uploadedBy || null,
    };
  }

  async create(payload) {
    const task = this.extractTaskData(payload);
    task.attachments = [];
    const newTask = new Task(task);
    return await newTask.save();
  }

  async find(filter = {}) {
    return await Task.find(filter).lean();
  }

  async findAll() {
    return await Task.find({}).lean();
  }

  async findById(id) {
    return await Task.findById(id).lean();
  }

  async findByTaskId(task_id) {
    return await Task.findOne({
      task_id: { $regex: `^${task_id}$`, $options: "i" },
    }).lean();
  }

  async findByTaskName(task_name) {
    return await Task.find({
      task_name: { $regex: new RegExp(task_name, "i") },
    }).lean();
  }

  async findTaskByEmployee(employee_id) {
    return await Task.find({
      assigned_to: { $in: [employee_id] },
    }).lean();
  }

  async update(id, payload) {
    const update = this.extractTaskData(payload);
    return await Task.findByIdAndUpdate(id, update, { new: true }).lean();
  }

  async updateByTaskId(task_id, payload) {
    const update = this.extractTaskData(payload);
    return await Task.findOneAndUpdate({ task_id }, update, {
      new: true,
    }).lean();
  }

  async addAttachments(task_id, files, uploadedBy) {
    const attachments = files.map((file) =>
      this.extractAttachmentData(file, uploadedBy)
    );

    return await Task.findByIdAndUpdate(
      task_id,
      { $push: { attachments: { $each: attachments } } },
      { new: true }
    ).lean();
  }

  async addAttachmentsByTaskId(task_id, files, uploadedBy) {
    const attachments = files.map((file) =>
      this.extractAttachmentData(file, uploadedBy)
    );

    return await Task.findOneAndUpdate(
      { task_id },
      { $push: { attachments: { $each: attachments } } },
      { new: true }
    ).lean();
  }

  async removeAttachment(task_id, attachment_id) {
    const task = await Task.findOne({ task_id }).lean();
    if (!task) return null;

    const attachment = task.attachments?.find(
      (att) => att.attachment_id === attachment_id
    );

    if (attachment?.file_url && fs.existsSync(attachment.file_url)) {
      try {
        fs.unlinkSync(attachment.file_url);
      } catch (err) {
        console.error("Error deleting file:", err.message);
      }
    }

    return await Task.findOneAndUpdate(
      { task_id },
      { $pull: { attachments: { attachment_id } } },
      { new: true }
    ).lean();
  }

  async removeMultipleAttachments(task_id, attachment_ids) {
    const task = await Task.findOne({ task_id }).lean();
    if (!task) return null;

    task.attachments?.forEach((att) => {
      if (attachment_ids.includes(att.attachment_id) && att.file_url) {
        if (fs.existsSync(att.file_url)) {
          try {
            fs.unlinkSync(att.file_url);
          } catch (err) {
            console.error("Error deleting file:", err.message);
          }
        }
      }
    });

    return await Task.ﬁndOneAndUpdate(
      { task_id },
      { $pull: { attachments: { attachment_id: { $in: attachment_ids } } } },
      { new: true }
    ).lean();
  }

  async replaceAttachments(task_id, files, uploadedBy) {
    const oldTask = await Task.findOne({ task_id }).lean();
    if (oldTask?.attachments) {
      oldTask.attachments.forEach((att) => {
        if (att.file_url && fs.existsSync(att.file_url)) {
          try {
            fs.unlinkSync(att.file_url);
          } catch (err) {
            console.error("Error deleting old file:", err.message);
          }
        }
      });
    }

    const attachments = files.map((file) =>
      this.extractAttachmentData(file, uploadedBy)
    );

    return await Task.findOneAndUpdate(
      { task_id },
      { $set: { attachments } },
      { new: true }
    ).lean();
  }

  async delete(id) {
    const task = await Task.findById(id).lean();
    if (task?.attachments) {
      task.attachments.forEach((att) => {
        if (att.file_url && fs.existsSync(att.file_url)) {
          try {
            fs.unlinkSync(att.file_url);
          } catch (err) {
            console.error("Error deleting file:", err.message);
          }
        }
      });
    }

    const result = await Task.findByIdAndDelete(id);
    return result;
  }

  async deleteByTaskId(task_id) {
    const task = await Task.findOne({ task_id }).lean();
    if (task?.attachments) {
      task.attachments.forEach((att) => {
        if (att.file_url && fs.existsSync(att.file_url)) {
          try {
            fs.unlinkSync(att.file_url);
          } catch (err) {
            console.error("Error deleting file:", err.message);
          }
        }
      });
    }

    return await Task.findOneAndDelete({ task_id });
  }

  async deleteAll() {
    const tasks = await Task.find({}).lean();

    tasks.forEach((task) => {
      task.attachments?.forEach((att) => {
        if (att.file_url && fs.existsSync(att.file_url)) {
          try {
            fs.unlinkSync(att.file_url);
          } catch (err) {
            console.error("Error deleting file:", err.message);
          }
        }
      });
    });

    const result = await Task.deleteMany({});
    return result.deletedCount;
  }
}

module.exports = TaskService;
