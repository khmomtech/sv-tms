import { inject, Pipe, PipeTransform } from '@angular/core';
import { AuthService } from '../services/auth.service';

@Pipe({
  name: 'hasPermission',
  standalone: true,
})
export class HasPermissionPipe implements PipeTransform {
  private authService = inject(AuthService);

  transform(permission: string): boolean {
    return this.authService.hasPermission(permission);
  }
}
