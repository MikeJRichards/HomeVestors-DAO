import { defineConfig } from 'vite';
import { fileURLToPath, URL } from 'url';
import { resolve } from 'path';

import environment from 'vite-plugin-environment';
import dotenv from 'dotenv';

dotenv.config({ path: '../../.env' });

export default defineConfig({
  build: {
    emptyOutDir: true,
    rollupOptions: {
      input: {
        home: resolve(__dirname, 'index.html'),
        about: resolve(__dirname, 'AboutUs.html'),
        balances: resolve(__dirname, 'Balance.html'),
        propertyinfo: resolve(__dirname, 'IMP-PropertyPage.html'),
        marketplace: resolve(__dirname, 'marketplace.html'),
        myhomes: resolve(__dirname, 'MyHomes.html'),
        myproposals: resolve(__dirname, 'MyProposals.html'),
        newproperty: resolve(__dirname, 'NP-PropertyPage.html'),
      }
    }
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: "globalThis",
      },
    },
  },
  server: {
  proxy: {
    "/api": {
      target: "http://127.0.0.1:4943", // proxy backend API calls
      changeOrigin: true,
    },
  },
},
  publicDir: "assets",
  plugins: [
    environment("all", { prefix: "CANISTER_" }),
    environment("all", { prefix: "DFX_" }),
  ],
  resolve: {
    alias: [
      {
        find: "declarations",
        replacement: fileURLToPath(
          new URL("../declarations", import.meta.url)
        ),
      },
    ],
    dedupe: ['@dfinity/agent'],
  },
});
