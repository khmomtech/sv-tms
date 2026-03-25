//  1. Notification Model (models/notification.model.ts)
export interface Notification {
  id: number;
  title: string;
  message: string;
  type?: string;
  isRead: boolean;
  sender?: string;
  topic?: string;
  createdAt: string;
  referenceId?: string;
}
