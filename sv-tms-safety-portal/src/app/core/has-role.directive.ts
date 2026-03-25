import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';
import { AuthService } from './auth.service';

@Directive({ selector: '[hasRole]' })
export class HasRoleDirective {
  private role: string | undefined;
  constructor(private tpl: TemplateRef<any>, private vcr: ViewContainerRef, private auth: AuthService) {}

  @Input()
  set hasRole(role: string) {
    this.role = role;
    this.updateView();
  }

  private updateView(){
    const ok = this.role ? this.auth.isInRole(this.role) : false;
    this.vcr.clear();
    if(ok) this.vcr.createEmbeddedView(this.tpl);
  }
}
