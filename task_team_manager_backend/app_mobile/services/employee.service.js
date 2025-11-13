const { ObjectId } = require("mongodb");
const bcrypt = require("bcrypt");

class EmployeeService {
  constructor(client) {
    this.Employee = client.db().collection("employees");
  }

  extractEmployeeData(payload, image) {
    const employee = {
      employee_id: payload.employee_id,
      employee_name: payload.employee_name,
      employee_password: payload.employee_password,
      role_id: payload.role_id,
      email: payload.email,
      phone: payload.phone,
      birth: payload.birth,
      address: payload.address,
      image: image || payload.image, 
    };

    Object.keys(employee).forEach(
      (key) => employee[key] === undefined && delete employee[key]
    );

    return employee;
  }

  async create(payload, image) {
    const employee = this.extractEmployeeData(payload, image);

    employee.employee_password = await bcrypt.hash(
      employee.employee_password,
      12
    );

    const result = await this.Employee.insertOne(employee);
    return { ...employee, _id: result.insertedId };
  }

  async find(filter) {
    return await this.Employee.find(filter).toArray();
  }

  async findAll() {
    return await this.Employee.find({}).toArray();
  }

  async findById(id) {
    return await this.Employee.findOne({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async findByEmployeeId(employee_id) {
    return await this.Employee.findOne({
      employee_id: employee_id,
    });
  }

  async findByEmployeeName(employee_name) {
    return await this.find({
      employee_name: { $regex: new RegExp(employee_name), $options: "i" },
    });
  }

  async update(id, payload, image) {
    const filter = { _id: ObjectId.isValid(id) ? new ObjectId(id) : null };

    const existingEmployee = await this.Employee.findOne(filter);
    if (!existingEmployee) {
      throw new Error("Employee not found");
    }

    // Xử lý password
    if (
      payload.employee_password &&
      payload.employee_password !== existingEmployee.employee_password
    ) {
      payload.employee_password = await bcrypt.hash(
        payload.employee_password,
        12
      );
    } else {
      payload.employee_password = existingEmployee.employee_password;
    }

    // Xử lý image
    if (image) {
      payload.image = image;
    } else if (!payload.image && existingEmployee.image) {
      payload.image = existingEmployee.image;
    }

    const update = this.extractEmployeeData(payload);

    return await this.Employee.findOneAndUpdate(
      filter,
      { $set: update },
      { returnDocument: "after" }
    );
  }

  async updateByEmployeeId(employee_id, payload, image) {
    const filter = { employee_id: employee_id };
    const existingEmployee = await this.Employee.findOne(filter);

    if (!existingEmployee) {
      throw new Error("Employee not found");
    }

    // Xử lý password
    if (
      payload.employee_password &&
      payload.employee_password !== existingEmployee.employee_password
    ) {
      payload.employee_password = await bcrypt.hash(
        payload.employee_password,
        12
      );
    } else {
      payload.employee_password = existingEmployee.employee_password;
    }

    // Xử lý image
    if (image) {
      payload.image = image;
    } else if (!payload.image && existingEmployee.image) {
      payload.image = existingEmployee.image;
    }

    console.log("Final payload before update:", payload);

    const update = this.extractEmployeeData(payload);

    const result = await this.Employee.findOneAndUpdate(
      filter,
      { $set: update },
      { returnDocument: "after" }
    );

    return result;
  }

  async delete(id) {
    return await this.Employee.findOneAndDelete({
      _id: ObjectId.isValid(id) ? new ObjectId(id) : null,
    });
  }

  async deleteByEmployeeId(employee_id) {
    const result = await this.Employee.findOneAndDelete({
      employee_id: employee_id,
    });

    return result;
  }

  async deleteAll() {
    const result = await this.Employee.deleteMany({});
    return result.deletedCount;
  }
}

module.exports = { EmployeeService };
