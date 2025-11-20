const cron = require("node-cron");
const TaskService = require("./task.service");
const NotificationService = require("./notification.service");
const Notification = require("../models/notification.model");

class NotificationScheduler {
  constructor() {
    this.taskService = new TaskService();
    this.notificationService = new NotificationService();
  }

  async checkDeadlineNearTasks() {
    try {
      const now = new Date();
      const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

      console.log("\n" + "=".repeat(60));
      console.log("🔔 DEADLINE NEAR CHECK");
      console.log("=".repeat(60));
      console.log(`Current time: ${now.toISOString()}`);
      console.log(`Checking until: ${next24Hours.toISOString()}`);

      const tasks = await this.taskService.find({
        end_date: {
          $gt: now,
          $lte: next24Hours,
        },
        status: { $nin: ["done", "wait", "overdue"] },
      });

      console.log(`✅ Found ${tasks.length} tasks with deadline near\n`);

      if (tasks.length === 0) {
        console.log("No tasks with deadline near found.");
        return;
      }

      // Hiển thị thông tin các tasks tìm được
      tasks.forEach((task, index) => {
        const taskDeadline = new Date(task.end_date);
        const hoursUntilDeadline = (taskDeadline - now) / (1000 * 60 * 60);
        console.log(`${index + 1}. Task: ${task.task_id}`);
        console.log(`   Name: ${task.task_name}`);
        console.log(`   Deadline: ${this.formatDeadline(task.end_date)}`);
        console.log(`   Hours remaining: ${hoursUntilDeadline.toFixed(2)}h`);
        console.log(`   Status: ${task.status}`);
        console.log(
          `   Assigned to: ${task.assigned_to?.length || 0} people\n`
        );
      });

      // Xử lý từng task
      for (const task of tasks) {
        const taskDeadline = new Date(task.end_date);
        const hoursUntilDeadline = (taskDeadline - now) / (1000 * 60 * 60);

        const existingNotification = await Notification.findOne({
          task_id: task.task_id,
          type: "task_deadline_near",
          create_at: {
            $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
          },
        });

        if (existingNotification) {
          console.log(
            `⏭️  Skip: Notification already sent for task ${task.task_id}`
          );
          continue;
        }

        if (!task.assigned_to || task.assigned_to.length === 0) {
          console.log(`⏭️  Skip: No assignees for task ${task.task_id}`);
          continue;
        }

        const notifications = task.assigned_to.map((employeeId) => ({
          employee_id: employeeId,
          actor_id: "system",
          task_id: task.task_id,
          type: "task_deadline_near",
          message: `Nhiệm vụ "${
            task.task_name
          }" sắp đến hạn (${this.formatDeadline(
            task.end_date
          )}) - còn khoảng ${Math.round(hoursUntilDeadline)} giờ`,
          metadata: {
            task_id: task.task_id,
            task_name: task.task_name,
            priority: task.priority,
            end_date: task.end_date,
            project_id: task.project_id,
            hours_remaining: Math.round(hoursUntilDeadline),
          },
        }));

        await Notification.insertMany(notifications);
        console.log(
          `📨 Sent deadline near notification for task: ${task.task_id} to ${notifications.length} recipient(s)`
        );
      }

      console.log("\n✅ Deadline near check completed\n");
    } catch (error) {
      console.error("❌ Error checking deadline near tasks:", error);
    }
  }

  /**
   * Kiểm tra tasks đã quá hạn
   */
  async checkOverdueTasks() {
    try {
      const now = new Date();

      console.log("\n" + "=".repeat(60));
      console.log("⚠️  OVERDUE TASKS CHECK");
      console.log("=".repeat(60));
      console.log(`Current time: ${now.toISOString()}`);
      console.log(`Checking tasks with deadline before: ${now.toISOString()}`);

      const tasks = await this.taskService.find({
        end_date: { $lt: now },
        status: { $nin: ["done", "wait", "overdue"] },
      });

      console.log(`✅ Found ${tasks.length} overdue tasks\n`);

      if (tasks.length === 0) {
        console.log("No overdue tasks found.");
        return;
      }

      tasks.forEach((task, index) => {
        const taskDeadline = new Date(task.end_date);
        const overdueHours = (now - taskDeadline) / (1000 * 60 * 60);
        const overdueDays = this.calculateOverdueDays(task.end_date);

        console.log(`${index + 1}. Task: ${task.task_id}`);
        console.log(`   Name: ${task.task_name}`);
        console.log(`   Deadline: ${this.formatDeadline(task.end_date)}`);
        console.log(
          `   Overdue: ${overdueDays} day(s) (${overdueHours.toFixed(2)}h)`
        );
        console.log(`   Status: ${task.status}`);
        console.log(
          `   Assigned to: ${task.assigned_to?.length || 0} people\n`
        );
      });

      // Xử lý từng task
      for (const task of tasks) {
        const overdueDays = this.calculateOverdueDays(task.end_date);

        await this.taskService.updateByTaskId(task.task_id, {
          status: "overdue",
        });

        const existingNotification = await Notification.findOne({
          task_id: task.task_id,
          type: "task_overdue",
          create_at: {
            $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
          },
        });

        if (existingNotification) {
          console.log(
            `⏭️  Skip: Notification already sent for overdue task ${task.task_id}`
          );
          continue;
        }

        if (task.assigned_to && task.assigned_to.length > 0) {
          const notifications = task.assigned_to.map((employeeId) => ({
            employee_id: employeeId,
            actor_id: "system",
            task_id: task.task_id,
            type: "task_overdue",
            message: `Nhiệm vụ "${
              task.task_name
            }" đã quá hạn ${overdueDays} ngày (${this.formatDeadline(
              task.end_date
            )})`,
            metadata: {
              task_id: task.task_id,
              task_name: task.task_name,
              priority: task.priority,
              end_date: task.end_date,
              project_id: task.project_id,
              overdue_days: overdueDays,
            },
          }));

          await Notification.insertMany(notifications);
          console.log(
            `📨 Sent overdue notification for task: ${task.task_id} to ${notifications.length} assignee(s)`
          );
        }

        if (task.created_by) {
          const creatorNotification = await Notification.findOne({
            employee_id: task.created_by,
            task_id: task.task_id,
            type: "task_overdue",
            create_at: {
              $gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
            },
          });

          if (!creatorNotification) {
            await this.notificationService.createNotification({
              employee_id: task.created_by,
              actor_id: "system",
              task_id: task.task_id,
              type: "task_overdue",
              message: `Nhiệm vụ bạn tạo "${task.task_name}" đã quá hạn ${overdueDays} ngày`,
              metadata: {
                task_id: task.task_id,
                task_name: task.task_name,
                priority: task.priority,
                end_date: task.end_date,
                overdue_days: overdueDays,
              },
            });
            console.log(
              `📨 Sent overdue notification to task creator: ${task.created_by}`
            );
          }
        }
      }

      console.log("\n✅ Overdue check completed\n");
    } catch (error) {
      console.error("❌ Error checking overdue tasks:", error);
    }
  }

  formatDeadline(deadline) {
    const date = new Date(deadline);
    const day = date.getDate().toString().padStart(2, "0");
    const month = (date.getMonth() + 1).toString().padStart(2, "0");
    const year = date.getFullYear();
    const hours = date.getHours().toString().padStart(2, "0");
    const minutes = date.getMinutes().toString().padStart(2, "0");

    return `${day}/${month}/${year} ${hours}:${minutes}`;
  }

  calculateOverdueDays(deadline) {
    const now = new Date();
    const deadlineDate = new Date(deadline);
    const diffTime = now - deadlineDate;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  }

  start() {
    //Chạy mỗi 1 giây để test
    // cron.schedule("*/1 * * * * *", () => {
    //   console.log("Running deadline near check...");
    //   this.checkDeadlineNearTasks();
    // });

    // //Chạy mỗi 1 giây để test overdue
    // cron.schedule("*/1 * * * * *", () => {
    //   console.log("Running overdue check...");
    //   this.checkOverdueTasks();
    // });

    // Chạy mỗi 1 giờ để kiểm tra task sắp đến hạn
    cron.schedule("0 * * * *", () => {
      console.log("Running deadline near check...");
      this.checkDeadlineNearTasks();
    });

    // Chạy mỗi 1 giờ để kiểm tra task quá hạn
    cron.schedule("0 * * * *", () => {
      console.log("Running overdue check...");
      this.checkOverdueTasks();
    });

    // Hoặc chạy hàng ngày vào 8:00 AM
    cron.schedule("0 8 * * *", () => {
      console.log("Running daily deadline check at 8:00 AM...");
      this.checkDeadlineNearTasks();
      this.checkOverdueTasks();
    });

    console.log("Notification scheduler started");
  }
}

module.exports = new NotificationScheduler();
