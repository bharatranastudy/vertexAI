import { ChatOpenRouter } from "@langchain/openrouter";

const llm = new ChatOpenRouter({
  model: "openai/gpt-4o-mini",
  temperature: 0,
  maxTokens: 1024,
  // other params...
});

export default llm