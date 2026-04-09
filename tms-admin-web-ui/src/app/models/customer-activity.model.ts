export type ActivityType =
  | 'ORDER_CREATED'
  | 'ORDER_UPDATED'
  | 'ORDER_DELIVERED'
  | 'NOTE'
  | 'CALL'
  | 'EMAIL'
  | 'MEETING'
  | 'PAYMENT'
  | 'ISSUE'
  | 'STATUS_CHANGE'
  | 'ACCOUNT_CREATED';

export interface CustomerActivity {
  id?: number;
  customerId: number;
  type: ActivityType;
  title: string;
  description?: string;
  metadata?: Record<string, any>;
  relatedEntityId?: number;
  relatedEntityType?: string;
  createdBy?: string;
  createdByName?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface CustomerActivityRequest {
  customerId: number;
  type: ActivityType;
  title: string;
  description?: string;
  metadata?: Record<string, any>;
  relatedEntityId?: number;
  relatedEntityType?: string;
}

export interface CustomerHealthScore {
  customerId: number;
  score: number; // 0-100
  status: 'EXCELLENT' | 'GOOD' | 'FAIR' | 'POOR' | 'AT_RISK';
  factors: {
    orderFrequency: number;
    revenueGrowth: number;
    paymentPunctuality: number;
    engagementLevel: number;
    recency: number;
  };
  lastCalculated: string;
  recommendations?: string[];
}

export interface CustomerInsights {
  customerId: number;
  totalOrders: number;
  totalRevenue: number;
  averageOrderValue: number;
  lastOrderDate: string;
  firstOrderDate: string;
  orderFrequencyDays: number;
  lifetimeValue: number;
  revenueThisMonth: number;
  revenueLastMonth: number;
  revenueGrowthPercent: number;
  ordersThisMonth: number;
  ordersLastMonth: number;
  topProducts?: string[];
  preferredPaymentTerms?: string;
  healthScore?: CustomerHealthScore;
}
