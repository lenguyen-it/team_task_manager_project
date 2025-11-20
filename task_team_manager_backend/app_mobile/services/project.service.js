const Project = require("../models/project.model");

class ProjectService {
  extractProjectData(payload) {
    const project = {
      project_id: payload.project_id,
      parent_project_id: payload.parent_project_id,
      project_name: payload.project_name,
      project_manager_id: payload.project_manager_id,
      description: payload.description,
      start_date: payload.start_date ? new Date(payload.start_date) : undefined,
      end_date: payload.end_date ? new Date(payload.end_date) : undefined,
      status: payload.status,
    };

    Object.keys(project).forEach(
      (key) => project[key] === undefined && delete project[key]
    );

    return project;
  }

  async create(payload) {
    const project = this.extractProjectData(payload);
    const newProject = new Project(project);
    return await newProject.save();
  }

  async find(filter = {}) {
    return await Project.find(filter).lean();
  }

  async findAll() {
    return await Project.find({}).lean();
  }

  async findById(id) {
    return await Project.findById(id).lean();
  }

  async findByProjectId(project_id) {
    return await Project.findOne({
      project_id: { $regex: `^${project_id}$`, $options: "i" },
    }).lean();
  }

  async findByProjectName(project_name) {
    return await Project.find({
      project_name: { $regex: new RegExp(project_name, "i") },
    }).lean();
  }

  async update(id, payload) {
    const update = this.extractProjectData(payload);
    return await Project.findByIdAndUpdate(id, update, { new: true }).lean();
  }

  async updateByProjectId(project_id, payload) {
    const update = this.extractProjectData(payload);
    return await Project.findOneAndUpdate({ project_id }, update, {
      new: true,
    }).lean();
  }

  async delete(id) {
    return await Project.findByIdAndDelete(id);
  }

  async deleteByProjectId(project_id) {
    return await Project.findOneAndDelete({ project_id });
  }

  async deleteAll() {
    const result = await Project.deleteMany({});
    return result.deletedCount;
  }
}

module.exports = ProjectService;
