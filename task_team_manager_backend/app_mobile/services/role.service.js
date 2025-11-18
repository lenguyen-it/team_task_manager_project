// const { ObjectId } = require("mongodb");

// class RoleService {
//   constructor(client) {
//     this.Role = client.db().collection("roles");
//   }

//   extractRoleData(payload) {
//     const role = {
//       role_id: payload.role_id,
//       role_name: payload.role_name,
//       description: payload.description,
//     };

//     Object.keys(role).forEach(
//       (key) => role[key] === undefined && delete role[key]
//     );

//     return role;
//   }

//   async create(payload) {
//     const role = this.extractRoleData(payload);
//     return await this.Role.insertOne(role);
//   }

//   async find(filter) {
//     return await this.Role.find(filter).toArray();
//   }

//   async findAll() {
//     return await this.Role.find({}).toArray();
//   }

//   async findById(id) {
//     return await this.User.findOne({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async findByRoleId(role_id) {
//     return await this.Role.findOne({
//       role_id: { $regex: `^${role_id}$`, $options: "i" },
//     });
//   }

//   async findByRoleName(role_name) {
//     return await this.find({
//       role_name: { $regex: new RegExp(role_name), $options: "i" },
//     });
//   }

//   async update(id, payload) {
//     const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
//     const update = this.extractRoleData(payload);
//     return await this.Role.findOneAndUpdate(
//       filter,
//       { $set: update },
//       { returnDocument: "after" }
//     );
//   }

//   async updateByRoleId(role_id, payload) {
//     const updateData = this.extractRoleData(payload);
//     const result = await this.Role.findOneAndUpdate(
//       { role_id: role_id },
//       { $set: updateData },
//       { returnDocument: "after" }
//     );
//     return result;
//   }

//   async delete(id) {
//     return await this.Role.findOneAndDelete({
//       _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
//     });
//   }

//   async deleteByRoleId(role_id) {
//     const result = await this.Role.findOneAndDelete({
//       role_id: role_id,
//     });
//     return result;
//   }

//   async deleteAll() {
//     return (await this.Role.deleteMany({})).deletedCount;
//   }
// }

// module.exports = RoleService;

const Role = require("../models/role.model");

class RoleService {


  extractRoleData(payload) {
    const role = {
      role_id: payload.role_id,
      role_name: payload.role_name,
      description: payload.description,
    };

    Object.keys(role).forEach(
      (key) => role[key] === undefined && delete role[key]
    );
    return role;
  }

  async create(payload) {
    const role = this.extractRoleData(payload);
    const newRole = new Role(role);
    return await newRole.save();
  }

  async find(filter = {}) {
    return await Role.find(filter).lean();
  }

  async findAll() {
    return await Role.find({}).lean();
  }

  async findById(id) {
    return await Role.findById(id).lean();
  }

  async findByRoleId(role_id) {
    return await Role.findOne({
      role_id: { $regex: `^${role_id}$`, $options: "i" },
    }).lean();
  }

  async findByRoleName(role_name) {
    return await Role.find({
      role_name: { $regex: new RegExp(role_name, "i") },
    }).lean();
  }

  async update(id, payload) {
    const update = this.extractRoleData(payload);
    return await Role.findByIdAndUpdate(id, update, { new: true }).lean();
  }

  async updateByRoleId(role_id, payload) {
    const update = this.extractRoleData(payload);
    return await Role.findOneAndUpdate({ role_id }, update, {
      new: true,
    }).lean();
  }

  async delete(id) {
    const result = await Role.findByIdAndDelete(id);
    return result;
  }

  async deleteByRoleId(role_id) {
    return await Role.findOneAndDelete({ role_id });
  }

  async deleteAll() {
    const result = await Role.deleteMany({});
    return result.deletedCount;
  }
}

module.exports = RoleService;
