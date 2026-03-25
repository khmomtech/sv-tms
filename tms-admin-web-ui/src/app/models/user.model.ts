export interface Role {
  id: number;
  name: string;
}

export interface User {
  id?: number; // Optional for new users
  username: string;
  email: string;
  password?: string; // Optional: only used on creation or update
  roles: string[]; // Must match UserDto.roles (Set<String>)
}
