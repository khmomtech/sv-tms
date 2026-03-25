// Compatibility shim.
// Some older code imports `src/environments/environment`, while the app uses `src/app/environments/environment`
// (runtime-config aware). Keep both paths consistent.
export { environment } from '../app/environments/environment';
