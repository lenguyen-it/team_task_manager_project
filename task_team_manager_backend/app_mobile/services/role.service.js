const { ObjectId } = require("mongodb");

class RoleService {
  constructor(client) {
    this.Role = client.db().collection("roles");
  }

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
    return await this.Role.insertOne(role);
  }

  async find(filter) {
    return await this.Role.find(filter).toArray();
  }

  async findAll() {
    return await this.Role.find({}).toArray();
  }

  async findById(id) {
    return await this.User.findOne({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async findByRoleId(role_id) {
    return await this.Role.findOne({
      role_id: { $regex: `^${role_id}$`, $options: "i" },
    });
  }

  async findByRoleName(role_name) {
    return await this.find({
      role_name: { $regex: new RegExp(role_name), $options: "i" },
    });
  }

  async update(id, payload) {
    const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };
    const update = this.extractRoleData(payload);
    return await this.Role.findOneAndUpdate(
      filter,
      { $set: update },
      { returnDocument: "after" }
    );
  }

  async updateByRoleId(role_id, payload) {
    const updateData = this.extractRoleData(payload);
    const result = await this.Role.findOneAndUpdate(
      { role_id: role_id },
      { $set: updateData },
      { returnDocument: "after" }
    );
    return result;
  }

  async delete(id) {
    return await this.Role.findOneAndDelete({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async deleteByRoleId(role_id) {
    const result = await this.Role.findOneAndDelete({
      role_id: role_id,
    });
    return result;
  }

  async deleteAll() {
    return (await this.Role.deleteMany({})).deletedCount;
  }
}

module.exports = RoleService;
