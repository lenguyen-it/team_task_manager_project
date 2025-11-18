// const { ObjectId } = require("mongodb");

// class TaskTypeService {
//   constructor(client) {
//     this.TaskType = client.db().collection("task_types");
//   }

//   extractTaskTypeData(payload) {
//     const taksType = {
//       task_type_id: payload.task_type_id,
//       task_type_name: payload.task_type_name,
//       description: payload.description,
//     };

//     Object.keys(taksType).forEach(
//       (key) => taksType[key] === undefined && delete taksType[key]
//     );

//     return taksType;
//   }

//   async create(payload) {
//     const taskType = this.extractTaskTypeData(payload);
//     return await this.TaskType.insertOne(taskType);
//   }

//   async find(filter) {
//     return await this.TaskType.find(filter).toArray();
//   }

//   async findAll() {
//     return await this.TaskType.find({}).toArray();
//   }

//   async findById(id) {
//     return await this.User.findOne({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async findByTaskTypeId(task_type_id) {
//     return await this.TaskType.findOne({
//       task_type_id: { $regex: `^${task_type_id}$`, $options: "i" },
//     });
//   }

//   async findByTaskTypeName(task_type_name) {
//     return await this.find({
//       task_type_name: { $regex: new RegExp(task_type_name), $options: "i" },
//     });
//   }

//   async update(id, payload) {
//     const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
//     const update = this.extractTaskTypeData(payload);
//     return await this.TaskType.findOneAndUpdate(
//       filter,
//       { $set: update },
//       { returnDocument: "after" }
//     );
//   }

//   async updateByTaskTypeId(task_type_id, payload) {
//     const updateData = this.extractTaskTypeData(payload);
//     const result = await this.TaskType.findOneAndUpdate(
//       { task_type_id: task_type_id },
//       { $set: updateData },
//       { returnDocument: "after" }
//     );
//     return result;
//   }

//   async delete(id) {
//     return await this.TaskType.findOneAndDelete({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   // Delete by task_type_id
//   async deleteByTaskTypeId(task_type_id) {
//     const result = await this.TaskType.findOneAndDelete({
//       task_type_id: task_type_id,
//     });
//     return result;
//   }

//   async deleteAll() {
//     return (await this.TaskType.deleteMany({})).deletedCount;
//   }
// }

// module.exports = TaskTypeService;

// services/tasktype.service.js
const TaskType = require("../models/tasktype.model");

class TaskTypeService {
  extractTaskTypeData(payload) {
    const taskType = {
      task_type_id: payload.task_type_id,
      task_type_name: payload.task_type_name,
      description: payload.description,
    };

    Object.keys(taskType).forEach(
      (key) => taskType[key] === undefined && delete taskType[key]
    );

    return taskType;
  }

  async create(payload) {
    const taskType = this.extractTaskTypeData(payload);
    const newTaskType = new TaskType(taskType);
    return await newTaskType.save();
  }

  async find(filter = {}) {
    return await TaskType.find(filter).lean();
  }

  async findAll() {
    return await TaskType.find({}).lean();
  }

  async findById(id) {
    return await TaskType.findById(id).lean();
  }

  async findByTaskTypeId(task_type_id) {
    return await TaskType.findOne({
      task_type_id: { $regex: `^${task_type_id}$`, $options: "i" },
    }).lean();
  }

  async findByTaskTypeName(task_type_name) {
    return await TaskType.find({
      task_type_name: { $regex: new RegExp(task_type_name, "i") },
    }).lean();
  }

  async update(id, payload) {
    const update = this.extractTaskTypeData(payload);
    return await TaskType.findByIdAndUpdate(id, update, { new: true }).lean();
  }

  async updateByTaskTypeId(task_type_id, payload) {
    const update = this.extractTaskTypeData(payload);
    return await TaskType.findOneAndUpdate({ task_type_id }, update, {
      new: true,
    }).lean();
  }

  async delete(id) {
    return await TaskType.findByIdAndDelete(id);
  }

  async deleteByTaskTypeId(task_type_id) {
    return await TaskType.findOneAndDelete({ task_type_id });
  }

  async deleteAll() {
    const result = await TaskType.deleteMany({});
    return result.deletedCount;
  }
}

module.exports = TaskTypeService;
