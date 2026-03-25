// Compatibility shim.
// Some older code imports `src/environments/environment.prod`, while the app uses
// `src/app/environments/environment.prod` (runtime-config aware).
export { environment } from '../app/environments/environment.prod';
