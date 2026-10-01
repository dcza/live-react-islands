import { exposeSSR } from "@live-react-islands/core/ssr";
import islands from "./islands";

await exposeSSR({ islands });
