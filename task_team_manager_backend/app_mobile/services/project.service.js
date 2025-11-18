// const { ObjectId } = require("mongodb");

// class ProjectService {
//   constructor(client) {
//     this.Project = client.db().collection("projects");
//   }

//   extractProjectData(payload) {
//     const project = {
//       project_id: payload.project_id,
//       project_name: payload.project_name,
//       project_manager_id: payload.project_manager_id,
//       description: payload.description,
//       start_date: payload.start_date,
//       end_date: payload.end_date,
//       status: payload.status,
//     };

//     Object.keys(project).forEach(
//       (key) => project[key] == undefined && delete project[key]
//     );

//     return project;
//   }

//   async create(payload) {
//     const project = this.extractProjectData(payload);
//     return await this.Project.insertOne(project);
//   }

//   async find(filter) {
//     return await this.Project.find(filter).toArray();
//   }

//   async findAll() {
//     return await this.Project.find({}).toArray();
//   }

//   async findById(id) {
//     return await this.Project.findOne({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async findByProjectId(project_id) {
//     return await this.Project.findOne({
//       project_id: { $regex: `^${project_id}$`, $options: "i" },
//     });
//   }

//   async findByProjectName(project_name) {
//     return await this.find({
//       project_name: { $regex: new RegExp(project_name), $options: "i" },
//     });
//   }

//   async update(id, payload) {
//     const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
//     const update = this.extractProjectData(payload);

//     return await this.Project.findOneAndUpdate(
//       filter,
//       { $set: update },
//       { returnDocument: "after" }
//     );
//   }

//   async updateByProjectId(project_id, payload) {
//     const updateData = this.extractProjectData(payload);
//     const result = await this.Project.findOneAndUpdate(
//       { project_id: project_id },
//       { $set: updateData },
//       { returnDocument: "after" }
//     );
//     return result;
//   }

//   async delete(id) {
//     return await this.Project.findOneAndDelete({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async deleteByProjectId(project_id) {
//     const result = await this.Project.findOneAndDelete({
//       project_id: project_id,
//     });
//     return result;
//   }

//   async deleteAll() {
//     return (await this.Project.deleteMany({})).deleteCount;
//   }
// }

// module.exports = ProjectService;

// services/project.service.js
const Project = require("../models/project.model");

class ProjectService {
  extractProjectData(payload) {
    const project = {
      project_id: payload.project_id,
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
