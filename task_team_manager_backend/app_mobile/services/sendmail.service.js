const nodemailer = require("nodemailer");

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST || "smtp.gmail.com",
      port: process.env.EMAIL_PORT || 587,
      secure: false,
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.APP_PASSWORD,
      },
    });
  }

  /**
   * Gửi email thông báo task mới
   */
  async sendTaskAssignmentEmail(task, assignees) {
    try {
      const emailPromises = assignees.map(async (assignee) => {
        if (!assignee.email) return null;

        const mailOptions = {
          from: `"Task Management System" <${process.env.EMAIL_USER}>`,
          to: assignee.email,
          subject: `🎯 Nhiệm vụ mới: ${task.task_name}`,
          html: this.getTaskAssignmentTemplate(task, assignee),
        };

        return await this.transporter.sendMail(mailOptions);
      });

      const results = await Promise.allSettled(emailPromises);

      const successful = results.filter((r) => r.status === "fulfilled").length;
      const failed = results.filter((r) => r.status === "rejected").length;

      console.log(`Email sent: ${successful} successful, ${failed} failed`);

      return { successful, failed };
    } catch (error) {
      console.error("Error sending task assignment emails:", error);
      throw error;
    }
  }

  /**
   * Template HTML cho email task assignment
   */
  getTaskAssignmentTemplate(task, assignee) {
    const priorityColors = {
      low: "#28a745",
      medium: "#ffc107",
      high: "#fd7e14",
      urgent: "#dc3545",
    };

    const priorityLabels = {
      low: "Thấp",
      medium: "Trung bình",
      high: "Cao",
      urgent: "Khẩn cấp",
    };

    const statusLabels = {
      new_task: "Công việc mới",
      in_progress: "Đang tiến hành",
      done: "Đã hoàn thành",
      wait_comfirm: "Chờ xác nhận",
      pause: "Tạm dừng",
      overdue: "Quá hạn",
    };

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <!--[if mso]>
        <style type="text/css">
          table { border-collapse: collapse; }
          .header { padding: 30px !important; }
        </style>
        <![endif]-->
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            font-family: Arial, sans-serif; 
            line-height: 1.6; 
            color: #333333;
            -webkit-text-size-adjust: 100%;
            -ms-text-size-adjust: 100%;
          }
          table { 
            border-collapse: collapse; 
            mso-table-lspace: 0pt; 
            mso-table-rspace: 0pt; 
          }
          img { 
            border: 0; 
            height: auto; 
            line-height: 100%; 
            outline: none; 
            text-decoration: none; 
          }
          .priority-badge { 
            display: inline-block; 
            padding: 5px 15px; 
            border-radius: 20px; 
            color: #ffffff !important; 
            font-size: 12px; 
            font-weight: bold; 
            mso-line-height-rule: exactly;
          }
        </style>
      </head>
      <body style="margin: 0; padding: 0; background-color: #f4f4f4;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #f4f4f4;">
          <tr>
            <td align="center" style="padding: 20px 0;">
              
              <!-- Main Container -->
              <table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="max-width: 600px; background-color: #ffffff;">
                
                <!-- Header -->
                <tr>
                  <td align="center" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); background-color: #667eea; padding: 30px; border-radius: 10px 10px 0 0;">
                    <!--[if mso]>
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                      <tr>
                        <td align="center">
                    <![endif]-->
                    <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: bold;">
                      &#127919; Bạn có nhiệm vụ mới!
                    </h1>
                    <!--[if mso]>
                        </td>
                      </tr>
                    </table>
                    <![endif]-->
                  </td>
                </tr>
                
                <!-- Content -->
                <tr>
                  <td style="background-color: #f9f9f9; padding: 30px;">
                    
                    <p style="margin: 0 0 15px 0; color: #333333; font-size: 14px;">
                      Xin chào <strong>${
                        assignee.name || assignee.employee_name
                      }</strong>,
                    </p>
                    
                    <p style="margin: 0 0 20px 0; color: #333333; font-size: 14px;">
                      Bạn vừa được giao một nhiệm vụ mới. Dưới đây là chi tiết:
                    </p>
                    
                    <!-- Task Info Box -->
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #ffffff; border-radius: 8px; margin: 20px 0;">
                      <tr>
                        <td style="padding: 20px;">
                          
                          <!-- Task Name -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#128203; Tên công việc:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                <strong>${task.task_name}</strong>
                              </td>
                            </tr>
                          </table>
                          
                          <!-- Task ID -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#127381; Mã công việc:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                ${task.task_id}
                              </td>
                            </tr>
                          </table>
                          
                          ${
                            task.description
                              ? `
                          <!-- Description -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#128221; Mô tả:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                ${task.description}
                              </td>
                            </tr>
                          </table>
                          `
                              : ""
                          }
                          
                          <!-- Priority -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#9889; Độ ưu tiên:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                <span class="priority-badge" style="background-color: ${
                                  priorityColors[task.priority] || "#6c757d"
                                };">
                                  ${
                                    priorityLabels[task.priority] ||
                                    task.priority
                                  }
                                </span>
                              </td>
                            </tr>
                          </table>
                          
                          <!-- Status -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#128202; Trạng thái:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                ${statusLabels[task.status] || "Chưa bắt đầu"}
                              </td>
                            </tr>
                          </table>
                          
                          ${
                            task.due_date
                              ? `
                          <!-- Due Date -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#128197; Hạn chót:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                ${new Date(task.due_date).toLocaleDateString(
                                  "vi-VN"
                                )}
                              </td>
                            </tr>
                          </table>
                          `
                              : ""
                          }
                          
                          ${
                            task.project_name
                              ? `
                          <!-- Project -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#128193; Dự án:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                <strong>${task.project_name}</strong>
                              </td>
                            </tr>
                          </table>
                          `
                              : ""
                          }
                          
                          ${
                            task.task_type_name
                              ? `
                          <!-- Task Type -->
                          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eeeeee;">
                            <tr>
                              <td width="120" style="color: #666666; font-weight: bold; font-size: 14px; vertical-align: top;">
                                &#127991; Loại công việc:
                              </td>
                              <td style="color: #333333; font-size: 14px;">
                                ${task.task_type_name}
                              </td>
                            </tr>
                          </table>
                          `
                              : ""
                          }
                          
                        </td>
                      </tr>
                    </table>
                    
                    <!-- Info Box -->
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #e3f2fd; border-radius: 8px; margin: 20px 0;">
                      <tr>
                        <td align="center" style="padding: 20px;">
                          <p style="margin: 0 0 10px 0; font-size: 14px; color: #1976d2;">
                            &#128241; <strong>Mở ứng dụng Task Management trên điện thoại để xem chi tiết</strong>
                          </p>
                          <p style="margin: 0; font-size: 12px; color: #666666;">
                            Mã task: <strong>${task.task_id}</strong>
                          </p>
                        </td>
                      </tr>
                    </table>
                    
                    <p style="margin: 30px 0 0 0; color: #666666; font-size: 14px;">
                      &#128161; <em>Hãy truy cập hệ thống để cập nhật tiến độ và trao đổi với team nhé!</em>
                    </p>
                    
                  </td>
                </tr>
                
                <!-- Footer -->
                <tr>
                  <td align="center" style="background-color: #f9f9f9; padding: 20px 30px 30px 30px; border-top: 1px solid #dddddd;">
                    <p style="margin: 0 0 10px 0; color: #666666; font-size: 12px;">
                      Email này được gửi tự động từ hệ thống Task Management
                    </p>
                    <p style="margin: 0; color: #666666; font-size: 12px;">
                      Nếu có thắc mắc, vui lòng liên hệ quản trị viên
                    </p>
                  </td>
                </tr>
                
              </table>
              
            </td>
          </tr>
        </table>
      </body>
      </html>
      `;
  }
}

module.exports = EmailService;
