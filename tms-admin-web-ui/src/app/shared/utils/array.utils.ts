/**
 * Array Utility Functions
 *
 * Helper functions for array manipulation, sorting, filtering, and grouping.
 * Useful for client-side data operations in tables and lists.
 *
 * @example
 * import { ArrayUtils } from '@shared/utils/array.utils';
 *
 * const sorted = ArrayUtils.sortBy(data, 'name', 'asc');
 * const grouped = ArrayUtils.groupBy(data, 'status');
 * const paginated = ArrayUtils.paginate(data, 1, 10);
 */
export class ArrayUtils {
  /**
   * Sort array by property (supports nested properties)
   * @param array Array to sort
   * @param key Property key to sort by (supports dot notation: 'user.name')
   * @param order Sort order: 'asc' or 'desc'
   */
  static sortBy<T>(array: T[], key: keyof T | string, order: 'asc' | 'desc' = 'asc'): T[] {
    if (!array || array.length === 0) return array;

    return [...array].sort((a, b) => {
      const aVal = this.getNestedValue(a, key as string);
      const bVal = this.getNestedValue(b, key as string);

      if (aVal === bVal) return 0;

      const comparison = aVal < bVal ? -1 : 1;
      return order === 'asc' ? comparison : -comparison;
    });
  }

  /**
   * Get nested property value using dot notation
   */
  private static getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((current, prop) => current?.[prop], obj);
  }

  /**
   * Filter array by search query (searches multiple properties)
   * @param array Array to filter
   * @param query Search query
   * @param properties Properties to search in
   */
  static filterByQuery<T>(array: T[], query: string, properties: (keyof T | string)[]): T[] {
    if (!query || query.trim() === '') return array;

    const lowerQuery = query.toLowerCase();

    return array.filter((item) =>
      properties.some((prop) => {
        const value = this.getNestedValue(item, prop as string);
        return value?.toString().toLowerCase().includes(lowerQuery);
      }),
    );
  }

  /**
   * Group array by property
   * @param array Array to group
   * @param key Property to group by
   * @returns Object with groups
   */
  static groupBy<T>(array: T[], key: keyof T | string): Record<string, T[]> {
    if (!array || array.length === 0) return {};

    return array.reduce(
      (groups, item) => {
        const groupKey = String(this.getNestedValue(item, key as string));
        if (!groups[groupKey]) {
          groups[groupKey] = [];
        }
        groups[groupKey].push(item);
        return groups;
      },
      {} as Record<string, T[]>,
    );
  }

  /**
   * Get unique values from array
   * @param array Array to get unique values from
   * @param key Optional property to check uniqueness by
   */
  static unique<T>(array: T[], key?: keyof T | string): T[] {
    if (!array || array.length === 0) return array;

    if (key) {
      const seen = new Set();
      return array.filter((item) => {
        const value = this.getNestedValue(item, key as string);
        if (seen.has(value)) return false;
        seen.add(value);
        return true;
      });
    }

    return Array.from(new Set(array));
  }

  /**
   * Paginate array
   * @param array Array to paginate
   * @param page Page number (1-based)
   * @param pageSize Items per page
   */
  static paginate<T>(array: T[], page: number, pageSize: number): T[] {
    if (!array || array.length === 0) return array;

    const startIndex = (page - 1) * pageSize;
    return array.slice(startIndex, startIndex + pageSize);
  }

  /**
   * Get pagination info
   */
  static getPaginationInfo(
    totalItems: number,
    page: number,
    pageSize: number,
  ): {
    totalPages: number;
    startIndex: number;
    endIndex: number;
    hasNext: boolean;
    hasPrev: boolean;
  } {
    const totalPages = Math.ceil(totalItems / pageSize);
    const startIndex = (page - 1) * pageSize;
    const endIndex = Math.min(startIndex + pageSize, totalItems);

    return {
      totalPages,
      startIndex,
      endIndex,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    };
  }

  /**
   * Chunk array into smaller arrays
   * @param array Array to chunk
   * @param size Chunk size
   */
  static chunk<T>(array: T[], size: number): T[][] {
    if (!array || array.length === 0) return [];

    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  /**
   * Flatten nested array
   */
  static flatten<T>(array: any[]): T[] {
    return array.reduce((flat, item) => {
      return flat.concat(Array.isArray(item) ? this.flatten(item) : item);
    }, []);
  }

  /**
   * Remove duplicates and null/undefined values
   */
  static compact<T>(array: (T | null | undefined)[]): T[] {
    return array.filter((item): item is T => item != null);
  }

  /**
   * Find item by property value
   */
  static findBy<T>(array: T[], key: keyof T | string, value: any): T | undefined {
    return array.find((item) => this.getNestedValue(item, key as string) === value);
  }

  /**
   * Find all items by property value
   */
  static findAllBy<T>(array: T[], key: keyof T | string, value: any): T[] {
    return array.filter((item) => this.getNestedValue(item, key as string) === value);
  }

  /**
   * Sum array values by property
   */
  static sumBy<T>(array: T[], key: keyof T | string): number {
    return array.reduce((sum, item) => {
      const value = Number(this.getNestedValue(item, key as string)) || 0;
      return sum + value;
    }, 0);
  }

  /**
   * Get average of array values by property
   */
  static averageBy<T>(array: T[], key: keyof T | string): number {
    if (!array || array.length === 0) return 0;
    return this.sumBy(array, key) / array.length;
  }

  /**
   * Get minimum value by property
   */
  static minBy<T>(array: T[], key: keyof T | string): T | undefined {
    if (!array || array.length === 0) return undefined;

    return array.reduce((min, item) => {
      const itemValue = this.getNestedValue(item, key as string);
      const minValue = this.getNestedValue(min, key as string);
      return itemValue < minValue ? item : min;
    });
  }

  /**
   * Get maximum value by property
   */
  static maxBy<T>(array: T[], key: keyof T | string): T | undefined {
    if (!array || array.length === 0) return undefined;

    return array.reduce((max, item) => {
      const itemValue = this.getNestedValue(item, key as string);
      const maxValue = this.getNestedValue(max, key as string);
      return itemValue > maxValue ? item : max;
    });
  }

  /**
   * Count occurrences by property value
   */
  static countBy<T>(array: T[], key: keyof T | string): Record<string, number> {
    return array.reduce(
      (counts, item) => {
        const value = String(this.getNestedValue(item, key as string));
        counts[value] = (counts[value] || 0) + 1;
        return counts;
      },
      {} as Record<string, number>,
    );
  }

  /**
   * Shuffle array (randomize order)
   */
  static shuffle<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  /**
   * Take first N items
   */
  static take<T>(array: T[], count: number): T[] {
    return array.slice(0, count);
  }

  /**
   * Drop first N items
   */
  static drop<T>(array: T[], count: number): T[] {
    return array.slice(count);
  }

  /**
   * Check if arrays are equal (shallow comparison)
   */
  static isEqual<T>(array1: T[], array2: T[]): boolean {
    if (array1.length !== array2.length) return false;
    return array1.every((item, index) => item === array2[index]);
  }

  /**
   * Get difference between two arrays
   */
  static difference<T>(array1: T[], array2: T[]): T[] {
    return array1.filter((item) => !array2.includes(item));
  }

  /**
   * Get intersection of two arrays
   */
  static intersection<T>(array1: T[], array2: T[]): T[] {
    return array1.filter((item) => array2.includes(item));
  }

  /**
   * Get union of two arrays (unique values from both)
   */
  static union<T>(array1: T[], array2: T[]): T[] {
    return this.unique([...array1, ...array2]);
  }
}
