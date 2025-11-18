// const { ObjectId } = require("mongodb");
// const fs = require("fs");
// const path = require("path");

// class TaskService {
//   constructor(client) {
//     this.Task = client.db().collection("tasks");
//   }

//   extractTaskData(payload) {
//     const task = {
//       task_id: payload.task_id,
//       task_name: payload.task_name,
//       project_id: payload.project_id,
//       task_type_id: payload.task_type_id,
//       parent_task_id: payload.parent_task_id,
//       assigned_to: payload.assigned_to,
//       description: payload.description,
//       start_date: payload.start_date,
//       end_date: payload.end_date,
//       priority: payload.priority,
//       status: payload.status,
//     };

//     Object.keys(task).forEach(
//       (key) => task[key] === undefined && delete task[key]
//     );

//     return task;
//   }

//   extractAttachmentData(file, uploadedBy) {
//     return {
//       attachment_id: Date.now() + "-" + Math.round(Math.random() * 1e9), // Tạo unique ID
//       file_name: file.originalname || file.filename,
//       file_url: file.path || file.location,
//       file_type: file.mimetype,
//       size: file.size,
//       uploaded_at: new Date(),
//       uploaded_by: uploadedBy || null,
//     };
//   }

//   async create(payload) {
//     const task = this.extractTaskData(payload);
//     task.attachments = [];
//     return await this.Task.insertOne(task);
//   }

//   async find(filter) {
//     return await this.Task.find(filter).toArray();
//   }

//   async findAll() {
//     return await this.Task.find({}).toArray();
//   }

//   async findById(id) {
//     return await this.Task.findOne({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async findByTaskId(task_id) {
//     return await this.Task.findOne({
//       task_id: { $regex: `^${task_id}$`, $options: "i" },
//     });
//   }

//   async findByTaskName(task_name) {
//     return await this.Task.find({
//       task_name: { $regex: new RegExp(task_name), $options: "i" },
//     }).toArray();
//   }

//   async findTaskByEmployee(employee_id) {
//     try {
//       const tasks = await this.Task.find({
//         assigned_to: { $in: [employee_id] },
//       }).toArray();
//       return tasks;
//     } catch (error) {
//       throw new Error(
//         "Không thể lấy danh sách task của nhân viên: " + error.message
//       );
//     }
//   }

//   async update(id, payload) {
//     const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
//     const update = this.extractTaskData(payload);
//     const result = await this.Task.findOneAndUpdate(
//       filter,
//       { $set: update },
//       { returnDocument: "after" }
//     );
//     return result;
//   }

//   async updateByTaskId(task_id, payload) {
//     const update = this.extractTaskData(payload);
//     const result = await this.Task.findOneAndUpdate(
//       { task_id: task_id },
//       { $set: update },
//       { returnDocument: "after" }
//     );
//     return result;
//   }

//   async addAttachments(task_id, files, uploadedBy) {
//     const attachments = files.map((file) =>
//       this.extractAttachmentData(file, uploadedBy)
//     );

//     const filter = {
//       _id: ObjectId.isValid(task_id) ? new ObjectId(task_id) : null,
//     };
//     const result = await this.Task.findOneAndUpdate(
//       filter,
//       { $push: { attachments: { $each: attachments } } },
//       { returnDocument: "after" }
//     );

//     return result.value;
//   }

//   async addAttachmentsByTaskId(task_id, files, uploadedBy) {
//     const attachments = files.map((file) =>
//       this.extractAttachmentData(file, uploadedBy)
//     );

//     const result = await this.Task.findOneAndUpdate(
//       { task_id: task_id },
//       { $push: { attachments: { $each: attachments } } },
//       { returnDocument: "after" }
//     );

//     return result;
//   }

//   // Xóa một attachment theo attachment_id
//   async removeAttachment(task_id, attachment_id) {
//     const task = await this.Task.findOne({ task_id: task_id });

//     if (!task) {
//       return null;
//     }

//     const attachment = task.attachments?.find(
//       (att) => att.attachment_id === attachment_id
//     );

//     if (attachment && attachment.file_url) {
//       try {
//         if (fs.existsSync(attachment.file_url)) {
//           fs.unlinkSync(attachment.file_url);
//           console.log(`Deleted physical file: ${attachment.file_url}`);
//         } else {
//           console.log(`File not found: ${attachment.file_url}`);
//         }
//       } catch (error) {
//         console.error("Error deleting physical file:", error.message);
//       }
//     }

//     const result = await this.Task.findOneAndUpdate(
//       { task_id: task_id },
//       { $pull: { attachments: { attachment_id: attachment_id } } },
//       { returnDocument: "after" }
//     );

//     return result;
//   }

//   // Xóa nhiều attachments
//   async removeMultipleAttachments(task_id, attachment_ids) {
//     const task = await this.Task.findOne({ task_id: task_id });

//     if (!task) {
//       return null;
//     }

//     task.attachments?.forEach((att) => {
//       if (attachment_ids.includes(att.attachment_id) && att.file_url) {
//         try {
//           if (fs.existsSync(att.file_url)) {
//             fs.unlinkSync(att.file_url);
//           }
//         } catch (error) {
//           console.error("Error deleting physical file:", error.message);
//         }
//       }
//     });

//     const result = await this.Task.findOneAndUpdate(
//       { task_id: task_id },
//       { $pull: { attachments: { attachment_id: { $in: attachment_ids } } } },
//       { returnDocument: "after" }
//     );

//     return result.value;
//   }

//   // Thay thế toàn bộ attachments
//   async replaceAttachments(task_id, files, uploadedBy) {
//     const oldTask = await this.Task.findOne({ task_id: task_id });

//     if (oldTask && oldTask.attachments) {
//       oldTask.attachments.forEach((att) => {
//         if (att.file_url) {
//           try {
//             if (fs.existsSync(att.file_url)) {
//               fs.unlinkSync(att.file_url);
//             }
//           } catch (error) {
//             console.error("Error deleting old file:", error.message);
//           }
//         }
//       });
//     }

//     const attachments = files.map((file) =>
//       this.extractAttachmentData(file, uploadedBy)
//     );

//     const result = await this.Task.findOneAndUpdate(
//       { task_id: task_id },
//       { $set: { attachments } },
//       { returnDocument: "after" }
//     );

//     return result.value;
//   }

//   async delete(id) {
//     const task = await this.findById(id);

//     if (task && task.attachments) {
//       task.attachments.forEach((att) => {
//         if (att.file_url) {
//           try {
//             if (fs.existsSync(att.file_url)) {
//               fs.unlinkSync(att.file_url);
//             }
//           } catch (error) {
//             console.error("Error deleting attachment file:", error.message);
//           }
//         }
//       });
//     }

//     return await this.Task.findOneAndDelete({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async deleteByTaskId(task_id) {
//     const task = await this.findByTaskId(task_id);

//     if (task && task.attachments) {
//       task.attachments.forEach((att) => {
//         if (att.file_url) {
//           try {
//             if (fs.existsSync(att.file_url)) {
//               fs.unlinkSync(att.file_url);
//             }
//           } catch (error) {
//             console.error("Error deleting attachment file:", error.message);
//           }
//         }
//       });
//     }

//     const result = await this.Task.findOneAndDelete({ task_id: task_id });
//     return result;
//   }

//   async deleteAll() {
//     const tasks = await this.Task.find({}).toArray();

//     tasks.forEach((task) => {
//       if (task.attachments) {
//         task.attachments.forEach((att) => {
//           if (att.file_url) {
//             try {
//               if (fs.existsSync(att.file_url)) {
//                 fs.unlinkSync(att.file_url);
//               }
//             } catch (error) {
//               console.error("Error deleting attachment file:", error.message);
//             }
//           }
//         });
//       }
//     });

//     return (await this.Task.deleteMany({})).deletedCount;
//   }
// }

// module.exports = TaskService;

// services/task.service.js
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
      parent_task_id: payload.parent_task_id || null,
      assigned_to: payload.assigned_to || [],
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
