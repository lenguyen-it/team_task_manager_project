const { ObjectId } = require("mongodb");

class TaskService {
  constructor(client) {
    this.Task = client.db().collection("tasks");
  }

  extractTaskData(payload) {
    const task = {
      task_id: payload.task_id,
      task_name: payload.task_name,
      project_id: payload.project_id,
      task_type_id: payload.task_type_id,
      parent_task_id: payload.parent_task_id,
      assigned_to: payload.assigned_to,
      description: payload.description,
      start_date: payload.start_date || new Date(),
      end_date: payload.end_date || null,
      priority: payload.priority || "low",
      status: payload.status || "new_task",
    };

    Object.keys(task).forEach(
      (key) => task[key] === undefined && delete task[key]
    );

    return task;
  }

  async create(payload) {
    const task = this.extractTaskData(payload);
    return await this.Task.insertOne(task);
  }

  async find(filter) {
    return await this.Task.find(filter).toArray();
  }

  async findAll() {
    return await this.Task.find({}).toArray();
  }

  async findById(id) {
    return await this.Task.findOne({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async findByTaskId(task_id) {
    return await this.Task.findOne({
      task_id: { $regex: `^${task_id}$`, $options: "i" },
    });
  }

  async findByTaskName(task_name) {
    return await this.Task.find({
      task_name: { $regex: new RegExp(task_name), $options: "i" },
    }).toArray();
  }

  async findTaskByEmployee(employee_id) {
    try {
      const tasks = await this.Task.find({
        assigned_to: { $in: [employee_id] },
      }).toArray();
      return tasks;
    } catch {
      throw new Error(
        "Không thể lấy danh sách task của nhân viên: " + error.message
      );
    }
  }

  async update(id, payload) {
    const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
    const update = this.extractTaskData(payload);
    const result = await this.Task.findOneAndUpdate(
      filter,
      { $set: update },
      { returnDocument: "after" }
    );
    return result.value;
  }

  async updateByTaskId(task_id, payload) {
    const update = this.extractTaskData(payload);
    const result = await this.Task.findOneAndUpdate(
      { task_id: task_id },
      { $set: update },
      { returnDocument: "after" }
    );
    return result;
  }

  async delete(id) {
    return await this.Task.findOneAndDelete({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async deleteByTaskId(task_id) {
    const result = await this.Task.findOneAndDelete({ task_id: task_id });
    return result;
  }

  async deleteAll() {
    return (await this.Task.deleteMany({})).deletedCount;
  }
}

module.exports = TaskService;
