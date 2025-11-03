const { ObjectId } = require("mongodb");

class TaskTypeService {
  constructor(client) {
    this.TaskType = client.db().collection("task_types");
  }

  extractTaskTypeData(payload) {
    const taksType = {
      task_type_id: payload.task_type_id,
      task_type_name: payload.task_type_name,
      description: payload.description,
    };

    Object.keys(taksType).forEach(
      (key) => taksType[key] === undefined && delete taksType[key]
    );

    return taksType;
  }

  async create(payload) {
    const taskType = this.extractTaskTypeData(payload);
    return await this.TaskType.insertOne(taskType);
  }

  async find(filter) {
    return await this.TaskType.find(filter).toArray();
  }

  async findAll() {
    return await this.TaskType.find({}).toArray();
  }

  async findById(id) {
    return await this.User.findOne({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async findByTaskTypeId(task_type_id) {
    return await this.TaskType.findOne({ task_type_id: task_type_id });
  }

  async findByTaskTypeName(task_type_name) {
    return await this.find({
      task_type_name: { $regex: new RegExp(task_type_name), $options: "i" },
    });
  }

  async update(id, payload) {
    const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
    const update = this.extractTaskTypeData(payload);
    return await this.TaskType.findOneAndUpdate(
      filter,
      { $set: update },
      { returnDocument: "after" }
    );
  }

  async updateByTaskTypeId(task_type_id, payload) {
    const updateData = this.extractTaskTypeData(payload);
    const result = await this.TaskType.findOneAndUpdate(
      { task_type_id: task_type_id },
      { $set: updateData },
      { returnDocument: "after" }
    );
    return result.value;
  }

  async delete(id) {
    return await this.TaskType.findOneAndDelete({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  // Delete by task_type_id
  async deleteByTaskTypeId(task_type_id) {
    const result = await this.TaskType.findOneAndDelete({
      task_type_id: task_type_id,
    });
    return result.value;
  }

  async deleteAll() {
    return (await this.TaskType.deleteMany({})).deletedCount;
  }
}

module.exports = TaskTypeService;
