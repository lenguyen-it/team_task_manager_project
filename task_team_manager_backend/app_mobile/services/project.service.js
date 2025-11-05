const { ObjectId } = require("mongodb");

class ProjectService {
  constructor(client) {
    this.Project = client.db().collection("projects");
  }

  extractProjectData(payload) {
    const project = {
      project_id: payload.project_id,
      project_name: payload.project_name,
      description: payload.description,
      start_date: payload.start_date || new Date(),
      end_date: payload.end_date || null,
      status: payload.status || "planning",
    };

    Object.keys(project).forEach(
      (key) => project[key] == undefined && delete project[key]
    );

    return project;
  }

  async create(payload) {
    const project = this.extractProjectData(payload);
    return await this.Project.insertOne(project);
  }

  async find(filter) {
    return await this.Project.find(filter).toArray();
  }

  async findAll() {
    return await this.Project.find({}).toArray();
  }

  async findById(id) {
    return await this.User.findOne({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async findByProjectId(project_id) {
    return await this.Project.findOne({
      project_id: { $regex: `^${project_id}$`, $options: "i" },
    });
  }

  async findByProjectName(project_name) {
    return await this.find({
      project_name: { $regex: new RegExp(project_name), $options: "i" },
    });
  }

  async update(id, payload) {
    const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
    const update = this.extractProjectData(payload);

    return await this.Project.findOneAndUpdate(
      filter,
      { $set: update },
      { returnDocument: "after" }
    );
  }

  async updateByProjectId(project_id, payload) {
    const updateData = this.extractProjectData(payload);
    const result = await this.Project.findOneAndUpdate(
      { project_id: project_id },
      { $set: updateData },
      { returnDocument: "after" }
    );
    return result;
  }

  async delete(id) {
    return await this.Project.findOneAndDelete({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async deleteByProjectId(project_id) {
    const result = await this.Project.findOneAndDelete({
      project_id: project_id,
    });
    return result;
  }

  async deleteAll() {
    return (await this.Project.deleteMany({})).deleteCount;
  }
}

module.exports = ProjectService;
